const fs = require('fs');
const { renderPdf } = require('./src/services/reportService');

const caregiver = {
  name: 'Abdul Hafis Mohammed',
  phone: '233599880977',
  community: 'Zujung',
  district: 'Tamale Metro',
};
const assessment = {
  _id: '9d0e1243-d622-428d-8b6e-37c650f5de7a',
  subjectType: 'pregnancy',
  riskLevel: 'urgent',
  completedAt: new Date(),
  dangerSigns: ['Do you have severe belly pain?', 'Has your water broken?'],
  answers: [
    { questionId: 'core_bleeding', question: 'Have you had any vaginal bleeding?', answer: false },
    { questionId: 'core_fits', question: 'Have you had fits, or a severe headache with blurred vision?', answer: false },
    { questionId: 'core_pain', question: 'Do you have severe belly pain?', answer: true },
    { questionId: 'core_water', question: 'Has your water broken?', answer: true },
    { questionId: 'core_movement', question: 'Is the baby moving less than usual?', answer: false },
    { questionId: 'core_fever', question: 'Have you had a fever since your last check-in?', answer: false },
    { questionId: 'ai_q1', question: 'Are you still feeling very tired, or is it worse now?', answer: true },
    { questionId: 'ai_q2', question: 'Is your transport plan ready for delivery?', answer: false },
  ],
};
const history = [
  { completedAt: new Date(Date.now() - 86400000), subjectType: 'pregnancy', riskLevel: 'urgent', dangerSigns: ['Have you had fits, or a severe headache with blurred vision?'] },
  { completedAt: new Date(Date.now() - 86400000), subjectType: 'pregnancy', riskLevel: 'low', dangerSigns: [] },
  { completedAt: new Date(Date.now() - 2 * 86400000), subjectType: 'child', riskLevel: 'urgent', dangerSigns: ['Unconscious or very sleepy', 'Unable to drink or breastfeed'] },
  { completedAt: new Date(Date.now() - 3 * 86400000), subjectType: 'pregnancy', riskLevel: 'low', dangerSigns: [] },
];
const pregnancy = {
  expectedDueDate: new Date('2026-04-06'),
  hospitalName: 'Tamale Teaching Hospital',
  hospitalPhone: '0372022454',
};

renderPdf(caregiver, assessment, history, pregnancy, [-1.07872, 10.8674489]).then((buf) => {
  fs.writeFileSync('test-report.pdf', buf);
  console.log('written test-report.pdf', buf.length, 'bytes');
  // Also the no-GPS variant
  return renderPdf(caregiver, assessment, history, pregnancy, null);
}).then((buf) => {
  fs.writeFileSync('test-report-nogps.pdf', buf);
  console.log('written test-report-nogps.pdf', buf.length, 'bytes');
});
