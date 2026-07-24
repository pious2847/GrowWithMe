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
async function buildRiskReport(caregiver, assessment) {
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

    const pdf = await renderPdf(caregiver, assessment, history, pregnancy);
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

function renderPdf(caregiver, assessment, history, pregnancy) {
  return new Promise((resolve) => {
    const doc = new PDFDocument({ margin: 48 });
    const chunks = [];
    doc.on('data', (c) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));

    const green = '#1B5E20';
    doc.fillColor(green).fontSize(20).text('GrowWithMe — Urgent Risk Report', { align: 'left' });
    doc.moveDown(0.2);
    doc.fillColor('#666').fontSize(10)
      .text(`Generated ${new Date().toUTCString()} · Assessment ${assessment._id}`);
    doc.moveDown();

    doc.fillColor('#000').fontSize(13).text('Patient', { underline: true });
    doc.fontSize(11)
      .text(`Name: ${caregiver.name || 'Not provided'}`)
      .text(`Phone: ${caregiver.phone}`)
      .text(`Community: ${caregiver.community || '-'}  District: ${caregiver.district || '-'}`);
    if (pregnancy) {
      doc.text(
        `Pregnancy: expected due ${new Date(pregnancy.expectedDueDate).toDateString()}` +
          (pregnancy.hospitalName ? ` · Usual facility: ${pregnancy.hospitalName}` : '')
      );
    }
    doc.moveDown();

    doc.fillColor('#B71C1C').fontSize(13).text('Current urgent assessment', { underline: true });
    doc.fillColor('#000').fontSize(11)
      .text(`Completed: ${new Date(assessment.completedAt).toUTCString()}`)
      .text(`Subject: ${assessment.subjectType}`)
      .text(`Risk level: ${assessment.riskLevel.toUpperCase()}`);
    doc.moveDown(0.3).text('Danger signs:');
    for (const sign of assessment.dangerSigns || []) doc.text(`  • ${sign}`);
    if ((assessment.answers || []).length) {
      doc.moveDown(0.3).text('Reported answers:');
      for (const a of assessment.answers.slice(0, 20)) {
        doc.text(`  • ${a.questionId || a.question || '?'}: ${JSON.stringify(a.answer)}`);
      }
    }
    if (assessment.location && assessment.location.coordinates) {
      const [lng, lat] = assessment.location.coordinates;
      doc.moveDown(0.3).text(`Location at assessment: https://maps.google.com/?q=${lat},${lng}`);
    }
    doc.moveDown();

    doc.fillColor('#000').fontSize(13).text('Recent history', { underline: true });
    doc.fontSize(11);
    if (!history.length) doc.text('No earlier assessments on record.');
    for (const h of history) {
      doc.text(
        `  • ${new Date(h.completedAt).toDateString()} — ${h.subjectType} — ${h.riskLevel}` +
          ((h.dangerSigns || []).length ? ` (${h.dangerSigns.join(', ')})` : '')
      );
    }
    doc.moveDown();

    doc.fillColor('#666').fontSize(9).text(
      'This report was generated automatically by GrowWithMe from caregiver-reported ' +
        'symptoms using WHO IMCI-aligned screening. It is not a diagnosis. ' +
        'Please assess the patient clinically and record the outcome.'
    );
    doc.end();
  });
}

module.exports = { buildRiskReport };
