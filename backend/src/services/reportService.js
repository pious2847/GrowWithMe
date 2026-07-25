const PDFDocument = require('pdfkit');
const cloudinary = require('cloudinary').v2;
const Assessment = require('../models/Assessment');
const Pregnancy = require('../models/Pregnancy');
const logger = require('../utils/logger');

/**
 * Compiles a clinician-facing PDF risk report for an urgent assessment:
 * patient details, danger signs, assessment answers, and recent history —
 * uploaded to Cloudinary so the link travels by SMS to the hospital where
 * the patient does her checks, closing the follow-up loop.
 * Returns the hosted URL, or null on any failure (reports are best-effort).
 */
async function buildRiskReport(caregiver, assessment, coordinates) {
  try {
    const [history, pregnancy] = await Promise.all([
      Assessment.find({
        owner: caregiver._id,
        deleted: false,
        _id: { $ne: assessment._id },
      })
        .sort({ completedAt: -1 })
        .limit(6)
        .lean(),
      assessment.pregnancy
        ? Pregnancy.findById(assessment.pregnancy).lean()
        : Promise.resolve(null),
    ]);

    const pdf = await renderPdf(caregiver, assessment, history, pregnancy, coordinates);
    const uploaded = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: 'growwithme/reports',
          resource_type: 'raw',
          format: 'pdf',
          public_id: `risk-report-${assessment._id}`,
        },
        (err, result) => (err ? reject(err) : resolve(result))
      );
      stream.end(pdf);
    });
    logger.info(`[report] risk report uploaded: ${uploaded.secure_url}`);
    return uploaded.secure_url;
  } catch (err) {
    logger.error('[report] failed to build risk report:', err.message);
    return null;
  }
}

const GREEN = '#1B5E20';
const RED = '#B71C1C';
const BLUE = '#1565C0';
const GRAY = '#666666';

function subjectLabel(subjectType) {
  if (subjectType === 'child') return 'A child under 5';
  if (subjectType === 'pregnancy') return 'A pregnant mother';
  return 'A mother';
}

function riskColor(level) {
  if (level === 'urgent') return RED;
  if (level === 'moderate') return '#E65100';
  return '#2E7D32';
}

function renderPdf(caregiver, assessment, history, pregnancy, coordinates) {
  return new Promise((resolve) => {
    const doc = new PDFDocument({ margin: 48, size: 'A4' });
    const chunks = [];
    doc.on('data', (c) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));

    const margin = 48;
    const contentW = doc.page.width - margin * 2;

    const section = (title, color = GREEN) => {
      doc.moveDown(0.9);
      doc.font('Helvetica-Bold').fontSize(12).fillColor(color)
        .text(title.toUpperCase(), margin);
      const y = doc.y + 2;
      doc.moveTo(margin, y).lineTo(margin + contentW, y)
        .lineWidth(0.8).strokeColor('#DDDDDD').stroke();
      doc.moveDown(0.35);
    };

    const kv = (label, value) => {
      doc.font('Helvetica-Bold').fontSize(10.5).fillColor('#000')
        .text(`${label}:  `, margin, doc.y, { continued: true });
      doc.font('Helvetica').fillColor('#222').text(String(value));
      doc.moveDown(0.15);
    };

    // ---- Header band
    doc.rect(0, 0, doc.page.width, 88).fill(GREEN);
    doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(22)
      .text('GrowWithMe', margin, 20);
    doc.font('Helvetica').fontSize(12)
      .text('Urgent Maternal & Child Risk Report', margin, 48);
    doc.fillColor('#C8E6C9').fontSize(8.5)
      .text(`Generated ${new Date().toUTCString()}   ·   Ref ${assessment._id}`, margin, 68);
    doc.y = 106;

    // ---- Urgent banner
    const bannerY = doc.y;
    doc.roundedRect(margin, bannerY, contentW, 36, 6).fill(RED);
    doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(13).text(
      `URGENT — ${subjectLabel(assessment.subjectType)} needs immediate care`,
      margin + 14,
      bannerY + 11
    );
    doc.y = bannerY + 44;
    doc.x = margin;

    // ---- Patient
    section('Patient');
    kv('Name', caregiver.name || 'Not provided');
    kv('Phone', caregiver.phone);
    kv('Community', caregiver.community || 'Not provided');
    kv('District', caregiver.district || 'Not provided');
    if (pregnancy) {
      kv('Pregnancy', `due ${new Date(pregnancy.expectedDueDate).toDateString()}`);
      if (pregnancy.hospitalName) {
        kv('Usual check-up facility', pregnancy.hospitalName +
          (pregnancy.hospitalPhone ? ` (${pregnancy.hospitalPhone})` : ''));
      }
    }
    kv('Screened', new Date(assessment.completedAt).toUTCString());

    // ---- Location — the responder's first question is "where is she?"
    section('Where to find the patient', BLUE);
    if (coordinates && coordinates.length === 2) {
      const [lng, lat] = coordinates;
      const mapsUrl = `https://maps.google.com/?q=${lat},${lng}`;
      doc.font('Helvetica-Bold').fontSize(11.5).fillColor(BLUE).text(
        '>>  Tap here to open the patient\'s location in Google Maps',
        margin, doc.y,
        { link: mapsUrl, underline: true }
      );
      doc.moveDown(0.2);
      doc.font('Helvetica').fontSize(9.5).fillColor(GRAY)
        .text(`GPS coordinates: ${lat}, ${lng}   ·   ${mapsUrl}`, margin);
    } else {
      doc.font('Helvetica').fontSize(11).fillColor('#000').text(
        `No GPS position was available at the time of this alert. ` +
          `Please call the caregiver on ${caregiver.phone} to confirm where she is.`,
        margin
      );
    }

    // ---- Danger signs
    section('Danger signs reported', RED);
    const signs = assessment.dangerSigns || [];
    if (!signs.length) {
      doc.font('Helvetica').fontSize(11).fillColor('#000')
        .text('None recorded.', margin);
    }
    for (const sign of signs) {
      doc.font('Helvetica-Bold').fontSize(11).fillColor(RED)
        .text(`!  ${sign.replace(/\?$/, '')}  —  YES`, margin);
      doc.moveDown(0.1);
    }

    // ---- Full screening answers
    const answers = (assessment.answers || []).filter((a) => a.question || a.questionId);
    if (answers.length) {
      section('Full screening answers');
      for (const a of answers.slice(0, 20)) {
        const yes = a.answer === true || a.answer === 'true';
        const question = (a.question || a.questionId).replace(/\?$/, '');
        doc.font('Helvetica').fontSize(10).fillColor('#333')
          .text(`${question}  —  `, margin, doc.y, { continued: true });
        doc.font('Helvetica-Bold').fillColor(yes ? RED : '#2E7D32')
          .text(yes ? 'YES' : 'No');
        doc.moveDown(0.1);
      }
    }

    // ---- History
    section('Recent check-in history');
    doc.fontSize(10);
    if (!history.length) {
      doc.font('Helvetica').fillColor('#000')
        .text('No earlier assessments on record.', margin);
    }
    for (const h of history) {
      const label = h.subjectType === 'child' ? 'Child' : 'Pregnancy';
      doc.font('Helvetica').fillColor('#333').text(
        `${new Date(h.completedAt).toDateString()}  ·  ${label}  ·  `,
        margin, doc.y,
        { continued: true }
      );
      doc.font('Helvetica-Bold').fillColor(riskColor(h.riskLevel))
        .text(h.riskLevel.toUpperCase(), { continued: (h.dangerSigns || []).length > 0 });
      if ((h.dangerSigns || []).length) {
        doc.font('Helvetica').fillColor(GRAY)
          .text(`   (${h.dangerSigns.join('; ')})`);
      }
      doc.moveDown(0.1);
    }

    // ---- Footer
    doc.moveDown(1.2);
    doc.font('Helvetica').fillColor(GRAY).fontSize(8.5).text(
      'This report was generated automatically by GrowWithMe from caregiver-reported ' +
        'symptoms using WHO IMCI-aligned screening. It is not a diagnosis. ' +
        'Please assess the patient clinically and record the outcome.',
      margin
    );
    doc.end();
  });
}

module.exports = { buildRiskReport, renderPdf };
