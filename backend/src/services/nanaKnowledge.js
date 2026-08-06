/**
 * Nana's grounding knowledge — compiled from the Ghana Health Service /
 * WHO counseling materials in active use (Maternal & Child Health Record
 * Book pp. 58–59, GHS counseling cards: feeding recommendations Table 9,
 * danger sign charts, delivery health messages, Responsive Care packet).
 *
 * These blocks are injected into every AI prompt so Nana advises from the
 * SAME guidance frontline health workers use — never from model memory.
 * Keep them compact: they ride along on every LLM call.
 */

const FEEDING_KNOWLEDGE = `OFFICIAL GHS/WHO FEEDING RECOMMENDATIONS (follow exactly):
0-6 months: breast milk ONLY, day and night, whenever baby demands. No water, no glucose water, no herbal preparations, no other food or fluid. Continue breastfeeding up to 2 years or longer.
At 6 months (start complementary foods): 2-3 meals/day plus frequent breastfeeds. Start with 2-3 tablespoons per feed ("tastes") and increase gradually. Texture: thick porridge/pap, well mashed, without pepper.
6-9 months: 2-3 meals plus frequent breastfeeds, 1-2 snacks may be offered. Amount: 2-3 tablespoons per feed increasing gradually to half of a 250 ml cup/bowl. Texture: thick porridge/pap, mashed/pureed family foods. Give fruits every day.
9-12 months: 3-4 meals plus breastfeeds, 1-2 snacks. Amount: half of a 250 ml cup/bowl. Texture: finely chopped family foods, finger foods, sliced foods the child can pick up.
12-24 months: 3-4 meals plus breastfeeds, 1-2 snacks. Amount: three-quarters to one 250 ml cup/bowl. Texture: sliced foods, normal family foods. Teach the child to eat by himself/herself with a spoon and plate.
If the child (6-24 months) is NOT breastfed: add 1-2 extra meals and 1-2 snacks, plus 1-2 cups of milk per day, plus 2-3 cups of extra fluid, especially in hot weather.
THE 4-STAR DIET — every day, mix from all 4 groups: (1) staples (porridge, TZ, rice, maize, yam), (2) legumes and nuts (beans, groundnut), (3) animal foods (egg, fish, meat, milk), (4) fruits and vegetables (green leaves, mango, orange, pawpaw).`;

const PREGNANCY_DANGER_SIGNS = `OFFICIAL DANGER SIGNS IN PREGNANCY (any one = go to the health facility IMMEDIATELY):
bleeding; severe headache; swollen feet, arms or face; convulsive fits; severe abdominal pain; persistent vomiting; smelly or greenish water from the birth canal; baby moving less, more, or not at all; fever (raised body temperature); the bag of water breaking before the expected date of delivery; dizziness with difficult breathing and rapid heart beat.`;

const BABY_DANGER_SIGNS = `OFFICIAL SIGNS OF SERIOUS ILLNESS IN A BABY (any one = go to the health facility IMMEDIATELY):
baby not sucking the breast well; yellow skin or eyes; vomiting; weak body movement and weak crying; twitching or convulsions; diarrhoea or blood in the stool; body too hot or too cold to touch; umbilical cord wet and smelly; difficulty in breathing.`;

const PROTECTING_PREGNANCY = `PROTECTING THE PREGNANCY (official guidance):
- Take iron and folic acid tablets every day — low iron causes anaemia which makes mother and baby weak, sick and tired. Iron tablets are NOT dangerous for the baby.
- Sleep under a long-lasting insecticide-treated net every night — malaria can cause anaemia, preterm delivery, a small unhealthy baby, or death of mother or baby. The clinic gives anti-malaria tablets from the time she feels the baby move.
- Take deworming tablets as given at the clinic; take tetanus-diphtheria immunization once or twice during the antenatal period.
DO NOT during pregnancy: smoke; take alcohol; take unprescribed drugs or herbal concoctions; do strenuous work; lift heavy loads.`;

const LABOUR_AND_DELIVERY = `SIGNS OF LABOUR (any one = go to the health facility immediately): labour pains every 10-20 minutes becoming regular and more frequent; mucus or thick slimy fluid mixed with blood; the bag of water breaking.
DURING LABOUR: she may still eat, drink, urinate and walk around while preparing to go; take deep breaths through the nose and out through the mouth to relieve pain; feeling the need to use the toilet may mean the baby is coming — call for assistance; at the facility, follow the midwife's instructions.
PREPARING FOR DELIVERY (birth plan): arrange transport, helpers and where to deliver; save money for care and transport; have a valid health insurance (NHIS) card; identify a possible blood donor; prepare to breastfeed immediately after birth; if delivery happens unexpectedly at home, report to a health facility immediately.
WHAT TO PACK: 2 packets of sanitary pads and a bar of soap; a bottle of chlorhexidine; at least 4 disposable rubber sheets; at least 4 cloths for the mother; at least 2 cot sheets, socks, cap and dresses for the baby.
HIV (PMTCT): if she did not test for HIV during pregnancy she will be offered the test in labour; testing and taking medication prevents passing HIV to the baby.`;

const CHILD_MILESTONES = `DEVELOPMENTAL MILESTONES (if the child CANNOT do these at the age, visit the health facility):
1 month: stare at mother; utter small sounds; smile.
3 months: hold head up while lying on the belly; laugh; move head left and right.
6 months: imitate sounds; reach for the nearest object; roll over alone; turn head to follow a sound.
9 months: sit unsupported; say "ma-ma-ma" / "da-da-da"; enjoy playing alone and clapping; hold a biscuit.
12 months: pinch a small object; imitate simple words like "papa" or "mama"; stand and walk while holding on.
2 years: point to and identify body parts; climb and run; imitate chores like sweeping; scribble on paper.
HEARING warning signs (visit facility): does not turn toward new sounds or voices at 6 months; frequent ear infections or discharge; does not respond to calls unless seeing you at 12 months; not talking or talking strangely at 18 months.
SEEING warning signs (visit facility): red or discharging eyes; cloudy eyes; rubs eyes saying they hurt; bumps into things; holds head awkwardly to look; eyes looking in different directions; a white spot in the eye.`;

module.exports = {
  FEEDING_KNOWLEDGE,
  PREGNANCY_DANGER_SIGNS,
  BABY_DANGER_SIGNS,
  PROTECTING_PREGNANCY,
  LABOUR_AND_DELIVERY,
  CHILD_MILESTONES,
};
