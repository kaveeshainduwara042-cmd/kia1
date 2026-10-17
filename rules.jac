"""Deterministic Rules Engine for Sri Lanka Smart Hospital OPD System.

Design Principle: 'Rules before AI'.
Red-flag symptoms, test-preparation instructions, clinical risk scoring,
drug interaction matrices, and pediatric dosing algorithms are strictly deterministic.
Adheres to Sri Lanka Ministry of Health clinical management guidelines.
"""

# =====================================================================
# DATA OBJECT DEFINITIONS
# =====================================================================

obj RedFlagResult {
    has is_red_flag: bool,
        reason: str,
        route: str,
        action: str,
        triage_level: str;
}

obj TestPrepResult {
    has test: str,
        instructions: str,
        location: str,
        reporting_time: str;
}

obj FacilityProtocolResult {
    has facility_key: str,
        name: str,
        modality: str,
        prep_steps: list,
        contraindications: list,
        required_labs: list,
        estimated_duration_mins: int,
        nursing_notes: str;
}

obj ClinicalScoreResult {
    has score_name: str,
        score: int,
        risk_level: str,
        recommendation: str,
        criteria_met: list;
}

obj PediatricDoseResult {
    has medication: str,
        weight_kg: float,
        single_dose_mg: float,
        frequency: str,
        max_daily_dose_mg: float,
        instructions: str;
}

obj DrugInteractionAlert {
    has drug_a: str,
        drug_b: str,
        severity: str,
        mechanism: str,
        clinical_action: str;
}

obj AllergyCrossReactionAlert {
    has drug: str,
        allergen: str,
        severity: str,
        cross_reactivity_pct: str,
        warning: str;
}


# =====================================================================
# DETERMINISTIC EMERGENCY RED-FLAG ENGINE
# =====================================================================

def check_red_flags(symptoms: str) -> RedFlagResult {
    text = symptoms.lower();
    
    # English keywords
    is_chest_pain = "chest pain" in text or "heart attack" in text or "tightness in chest" in text or "crushing chest" in text;
    is_breathing = "difficulty breathing" in text or "severe breath" in text or "choking" in text or "gasping" in text or "cannot breathe" in text;
    is_bleeding = "heavy bleeding" in text or "coughing blood" in text or "vomiting blood" in text or "profuse bleeding" in text;
    is_stroke = "stroke" in text or "facial droop" in text or "slurred speech" in text or "sudden numbness" in text or "one side paralysis" in text;
    is_unconscious = "unconscious" in text or "fainted" in text or "loss of consciousness" in text or "unresponsive" in text or "seizure" in text;
    is_anaphylaxis = "anaphylaxis" in text or "throat swelling" in text or "severe allergic" in text;

    # Sinhala & Tamil script/transliteration matches
    is_sinhala_chest = ("පපුව" in text and "කැක්කුම" in text) or "papuwe kakkuma" in text;
    is_tamil_chest = ("நெஞ்சு" in text and "வலி" in text) or "nenju vali" in text;
    is_sinhala_breath = ("හුස්ම" in text and "අමාරු" in text) or "husma ganna amarui" in text;
    is_tamil_breath = ("மூச்சு" in text and "திணறල්" in text) or "moochu thinaran" in text;
    is_sinhala_bleed = ("ලේ" in text and "යනවා" in text) or "le yanawa" in text;
    is_tamil_bleed = ("இரத்த" in text and "போக்கு" in text) or "raththam" in text;

    if is_chest_pain or is_sinhala_chest or is_tamil_chest {
        return RedFlagResult(
            is_red_flag=True,
            reason="Possible Acute Coronary Syndrome (Chest Pain / Cardiac Alert)",
            route="Emergency Treatment Unit (ETU) - Resuscitation Bay",
            action="Immediate alert dispatched to ETU Medical Officer. Priority wheelchair/stretcher triage.",
            triage_level="Red (Emergency)"
        );
    }

    if is_breathing or is_sinhala_breath or is_tamil_breath {
        return RedFlagResult(
            is_red_flag=True,
            reason="Severe Respiratory Distress",
            route="Emergency Treatment Unit (ETU) - High Flow Oxygen Bay",
            action="Immediate oxygen support required. Escort patient to ETU immediately.",
            triage_level="Red (Emergency)"
        );
    }

    if is_bleeding or is_sinhala_bleed or is_tamil_bleed {
        return RedFlagResult(
            is_red_flag=True,
            reason="Severe Hemorrhage / Acute Bleeding",
            route="Emergency Treatment Unit (ETU) - Trauma Bay",
            action="Immediate pressure dressing & IV access team alerted.",
            triage_level="Red (Emergency)"
        );
    }

    if is_stroke {
        return RedFlagResult(
            is_red_flag=True,
            reason="Suspected Acute Stroke (FAST Protocol Alert)",
            route="Emergency Treatment Unit (ETU) - Stroke Pathway",
            action="Time-sensitive neurological assessment and CT triage required.",
            triage_level="Red (Emergency)"
        );
    }

    if is_unconscious {
        return RedFlagResult(
            is_red_flag=True,
            reason="Altered Mental Status / Loss of Consciousness",
            route="Emergency Treatment Unit (ETU) - Resuscitation Bay",
            action="Airway maintenance and vital signs check initiated.",
            triage_level="Red (Emergency)"
        );
    }

    if is_anaphylaxis {
        return RedFlagResult(
            is_red_flag=True,
            reason="Suspected Anaphylaxis / Airway Compromise",
            route="Emergency Treatment Unit (ETU)",
            action="Adrenaline protocol standby alert issued.",
            triage_level="Red (Emergency)"
        );
    }

    return RedFlagResult(
        is_red_flag=False,
        reason="Non-emergency symptom presentation",
        route="Outpatient Department (OPD) Specialty Clinic",
        action="Proceed with standard guided triage and queue registration.",
        triage_level="Green (Routine)"
    );
}


# =====================================================================
# COMPREHENSIVE 13-FACILITY TEST PREPARATION RULES
# =====================================================================

def get_test_preparation(test_name: str) -> TestPrepResult {
    t = test_name.lower();

    if "mri" in t or "magnetic resonance" in t {
        return TestPrepResult(
            test="MRI Scan (1.5T / 3.0T)",
            instructions="Strict metal screening mandatory. Remove all jewelry, dentures, hearing aids, and metal hairpins. Inform staff immediately if you have a cardiac pacemaker, aneurysm clips, or cochlear implants. Fast 4-6 hours if abdominal or pelvic scan. Lie still for 30-45 minutes.",
            location="Diagnostic Imaging Centre - MRI Suite (Basement Level)",
            reporting_time="08:00 AM - 04:30 PM"
        );
    }

    if "ct" in t or "computed tomography" in t {
        return TestPrepResult(
            test="CT Scan with Contrast",
            instructions="Strict 4 hours fasting required prior to scan. Ensure recent Serum Creatinine report is available. Inform radiology staff if you take Metformin for diabetes, have asthma, or have prior iodine dye allergy. Drink plenty of water after scan.",
            location="Radiology Department - CT Suite 1",
            reporting_time="08:00 AM - 04:00 PM"
        );
    }

    if "fasting" in t or "fbs" in t or "sugar" in t {
        return TestPrepResult(
            test="Fasting Blood Sugar (FBS)",
            instructions="Strict 8-10 hours overnight fasting required. Plain water is permitted. Avoid morning tea or breakfast.",
            location="Phlebotomy / Lab Room 4 (Ground Floor)",
            reporting_time="07:30 AM - 09:30 AM"
        );
    }

    if "lipid" in t or "cholesterol" in t {
        return TestPrepResult(
            test="Fasting Lipid Profile",
            instructions="10-12 hours fasting required. Avoid heavy oily or fried meals the night before.",
            location="Phlebotomy / Lab Room 4",
            reporting_time="07:30 AM - 09:30 AM"
        );
    }

    if "ultrasound" in t or "uss" in t {
        return TestPrepResult(
            test="Ultrasound Abdomen & Pelvis",
            instructions="Fasting for 6 hours. Drink 4-5 glasses of plain water 1 hour prior to scan; do not empty bladder (full bladder needed).",
            location="Radiology & Ultrasound Unit (Building B, 1st Floor)",
            reporting_time="08:30 AM - 01:00 PM"
        );
    }

    if "mammography" in t or "breast" in t {
        return TestPrepResult(
            test="Digital Mammography",
            instructions="Do not apply deodorants, perfumes, talcum powder, or lotions under the arms or on breasts on examination day. Wear a two-piece outfit for convenience. Best scheduled 1-2 weeks after the start of menstrual cycle.",
            location="Women's Imaging Centre (2nd Floor)",
            reporting_time="08:30 AM - 02:30 PM"
        );
    }

    if "x-ray" in t or "xray" in t or "chest" in t {
        return TestPrepResult(
            test="Chest X-Ray (PA View)",
            instructions="No dietary restrictions. Remove metal chains, pendants, and items with metal buttons.",
            location="Radiology Department - Room 102",
            reporting_time="08:00 AM - 03:00 PM"
        );
    }

    if "ecg" in t or "ekg" in t or "heart" in t {
        return TestPrepResult(
            test="Electrocardiogram (12-Lead ECG)",
            instructions="Rest quietly for 10 minutes prior. Avoid energy drinks or strenuous stair climbing right before.",
            location="Cardiology Diagnostic Room 6",
            reporting_time="08:00 AM - 04:00 PM"
        );
    }

    if "echo" in t or "echocardiogram" in t {
        return TestPrepResult(
            test="2D Transthoracic Echocardiogram",
            instructions="No fasting required. Take all routine cardiac medications as prescribed. Wear comfortable loose two-piece clothing. Examination takes approximately 20-30 minutes.",
            location="Cardiology Department - Echo Lab 2",
            reporting_time="08:30 AM - 03:30 PM"
        );
    }

    if "endoscopy" in t or "ogd" in t or "gastroscopy" in t {
        return TestPrepResult(
            test="Upper GI Endoscopy (OGD)",
            instructions="Strict fasting from midnight (minimum 8 hours). Do not drink water on morning of procedure. Arrange an accompanying adult escort for transport home if sedation is administered. Bring all previous endoscopy records.",
            location="Endoscopy Unit - Procedure Suite A",
            reporting_time="07:30 AM - 12:00 PM"
        );
    }

    if "colonoscopy" in t {
        return TestPrepResult(
            test="Colonoscopy",
            instructions="Follow clear liquid diet for 24 hours prior. Complete bowel preparation solution (PEG electrolyte) as instructed by clinic nurse. Strict fasting 6 hours prior to procedure time. Adult escort mandatory.",
            location="Endoscopy Unit - Suite B",
            reporting_time="07:30 AM - 01:00 PM"
        );
    }

    if "dialysis" in t or "hemodialysis" in t {
        return TestPrepResult(
            test="Hemodialysis Session",
            instructions="Protect arteriovenous (AV) fistula arm: do not allow blood pressure checks, venipunctures, or tight clothing on fistula arm. Weigh yourself on the unit scale prior to commencing session. Review dry weight target with duty nephrology nurse.",
            location="Renal Disease Centre - Dialysis Ward 8",
            reporting_time="06:30 AM - 06:00 PM"
        );
    }

    if "physio" in t or "rehabilitation" in t {
        return TestPrepResult(
            test="Physiotherapy Assessment & Therapy",
            instructions="Wear loose comfortable exercise attire and supportive flat footwear. Bring recent X-ray or MRI films and doctor's referral letter. Avoid heavy meals 1 hour before session.",
            location="Department of Physical Medicine & Rehabilitation (Ground Floor)",
            reporting_time="08:00 AM - 03:30 PM"
        );
    }

    if "urine" in t or "ufr" in t {
        return TestPrepResult(
            test="Urine Full Report (UFR)",
            instructions="Collect clean-catch midstream urine into the sterile plastic container provided at the specimen counter.",
            location="Clinical Pathology Sample Counter (Lab Annex)",
            reporting_time="08:00 AM - 02:00 PM"
        );
    }

    if "fbc" in t or "blood count" in t {
        return TestPrepResult(
            test="Full Blood Count (FBC)",
            instructions="No fasting required. Maintain regular water hydration.",
            location="Phlebotomy / Lab Room 2",
            reporting_time="07:30 AM - 03:00 PM"
        );
    }

    return TestPrepResult(
        test=test_name,
        instructions="Present patient slip at the Central Laboratory counter for specific preparation instructions.",
        location="Central Diagnostic Complex",
        reporting_time="08:00 AM - 02:00 PM"
    );
}


# =====================================================================
# CLINICAL SPECIALTY ROUTING RULES
# =====================================================================

def match_specialty_rule(symptoms: str, age: int, sex: str = "Unspecified") -> str {
    s = " " + symptoms.lower().replace(",", " ").replace(".", " ") + " ";
    
    # Age-based deterministic routing
    if age < 14 {
        return "Paediatrics";
    }

    # Cardiology checked first for cardiac symptoms
    if " palpitation" in s or " heart" in s or " cardiac" in s or " pulse" in s or " blood pressure" in s or " hypertension" in s {
        return "Cardiology";
    }

    # ENT keywords
    if " ear " in s or " earache" in s or " hearing" in s or " throat" in s or " tonsil" in s or " sinus" in s or " nose" in s or " nasal" in s {
        return "ENT (Otolaryngology)";
    }

    # Orthopaedics
    if " bone" in s or " fracture" in s or " joint" in s or " knee" in s or " back pain" in s or " sprain" in s or " arthritis" in s {
        return "Orthopaedics";
    }

    # Dermatology
    if " rash" in s or " itching" in s or " skin" in s or " eczema" in s or " pimple" in s or " scabies" in s {
        return "Dermatology";
    }

    # Ophthalmology
    if " eye" in s or " vision" in s or " blurry" in s or " cataract" in s or " conjunctivitis" in s {
        return "Ophthalmology";
    }

    # Psychiatry
    if " anxiety" in s or " depression" in s or " insomnia" in s or " mental" in s or " panic" in s {
        return "Psychiatry";
    }

    # Obstetrics / Gynaecology check
    if (sex.lower() == "female" or sex.lower() == "f") and (" pregnancy" in s or " menstrual" in s) {
        return "Obstetrics & Gynaecology";
    }

    # Default to General OPD
    return "General OPD";
}


# =====================================================================
# SRI LANKA DENGUE CLINICAL MANAGEMENT GUIDELINES ENGINE
# =====================================================================

def evaluate_dengue_guidelines(
    day_of_fever: int,
    warning_signs: list,
    platelet_count: int,
    pcv_percent: float
) -> dict {
    has_warning_signs = len(warning_signs) > 0;
    is_critical_phase = day_of_fever >= 3 and day_of_fever <= 7;
    thrombocytopenia = platelet_count < 100000;
    leukopenia_or_pcv_rise = pcv_percent >= 45.0;

    triage_decision = "OPD Monitoring";
    admission_required = False;
    iv_fluid_needed = False;
    review_interval_hours = 24;
    guideline_action = "Daily FBC check at OPD Lab. Oral fluids 2500 ml/day (king coconut, kanji, soup). Avoid NSAIDs.";

    if has_warning_signs or (is_critical_phase and thrombocytopenia) {
        admission_required = True;
        triage_decision = "Immediate Ward Admission";
        guideline_action = "Admit to Dengue Management Ward. Start maintenance IV fluid protocol (Normal Saline / Hartmans). 4-hourly HCT/PCV monitoring.";
        review_interval_hours = 4;
        iv_fluid_needed = True;
    }

    if "shock" in warning_signs or "hypotension" in warning_signs or "cold clammy extremities" in warning_signs {
        triage_decision = "Emergency Treatment Unit (ETU) Resuscitation";
        admission_required = True;
        iv_fluid_needed = True;
        guideline_action = "Dengue Shock Syndrome (DSS) protocol. Resuscitate with IV crystalloid 10-20 ml/kg over 1 hour. Urgent blood bank grouping and crossmatch.";
        review_interval_hours = 1;
    }

    return {
        "day_of_fever": day_of_fever,
        "is_critical_phase": is_critical_phase,
        "has_warning_signs": has_warning_signs,
        "thrombocytopenia": thrombocytopenia,
        "triage_decision": triage_decision,
        "admission_required": admission_required,
        "iv_fluid_needed": iv_fluid_needed,
        "review_interval_hours": review_interval_hours,
        "guideline_action": guideline_action
    };
}


# =====================================================================
# CLINICAL RISK SCORING ALGORITHMS
# =====================================================================

def calculate_curb65(
    confusion: bool,
    bun_gt_7: bool,
    rr_gte_30: bool,
    sbp_lt_90_or_dbp_lte_60: bool,
    age_gte_65: bool
) -> ClinicalScoreResult {
    score = 0;
    criteria = [];

    if confusion {
        score = score + 1;
        criteria.append("Mental Confusion (AMTS <= 8)");
    }
    if bun_gt_7 {
        score = score + 1;
        criteria.append("Urea > 7 mmol/L");
    }
    if rr_gte_30 {
        score = score + 1;
        criteria.append("Respiratory Rate >= 30/min");
    }
    if sbp_lt_90_or_dbp_lte_60 {
        score = score + 1;
        criteria.append("Blood Pressure: SBP < 90 or DBP <= 60 mmHg");
    }
    if age_gte_65 {
        score = score + 1;
        criteria.append("Age >= 65 years");
    }

    risk = "Low Risk (Mortality < 1%)";
    rec = "Outpatient management appropriate. Oral Amoxicillin or Macrolide as per Sri Lanka National Guidelines.";

    if score == 2 {
        risk = "Moderate Risk (Mortality ~ 9%)";
        rec = "Consider short hospital stay or close outpatient monitoring. Supervised oral or IV antibiotics.";
    } elif score >= 3 {
        risk = "High Risk (Mortality 15-40%)";
        rec = "Urgent hospital admission required. Assess for ICU/HDU transfer. IV broad-spectrum antibiotics.";
    }

    return ClinicalScoreResult(
        score_name="CURB-65 Pneumonia Severity Score",
        score=score,
        risk_level=risk,
        recommendation=rec,
        criteria_met=criteria
    );
}

def calculate_wells_dvt(criteria_active: list) -> ClinicalScoreResult {
    score = 0;
    criteria = [];

    if "active_cancer" in criteria_active {
        score = score + 1;
        criteria.append("Active cancer (treatment ongoing or within 6 months)");
    }
    if "paralysis_paresis" in criteria_active {
        score = score + 1;
        criteria.append("Paralysis, paresis, or recent plaster immobilization of lower limb");
    }
    if "bedridden" in criteria_active {
        score = score + 1;
        criteria.append("Recently bedridden > 3 days or major surgery within 12 weeks");
    }
    if "localized_tenderness" in criteria_active {
        score = score + 1;
        criteria.append("Localized tenderness along the deep venous system");
    }
    if "entire_leg_swollen" in criteria_active {
        score = score + 1;
        criteria.append("Entire leg swollen");
    }
    if "calf_swelling_gt_3cm" in criteria_active {
        score = score + 1;
        criteria.append("Calf swelling > 3 cm compared with asymptomatic leg");
    }
    if "pitting_edema" in criteria_active {
        score = score + 1;
        criteria.append("Pitting edema confined to symptomatic leg");
    }
    if "collateral_veins" in criteria_active {
        score = score + 1;
        criteria.append("Collateral superficial veins (non-varicose)");
    }
    if "alternative_dx_likely" in criteria_active {
        score = score - 2;
        criteria.append("Alternative diagnosis as likely or greater than DVT (-2 points)");
    }

    risk = "DVT Unlikely (<= 1 point)";
    rec = "Perform high-sensitivity D-Dimer test. If negative, DVT excluded. If positive, order compression ultrasound.";

    if score >= 2 {
        risk = "DVT Likely (>= 2 points)";
        rec = "Immediate venous duplex ultrasonography recommended. Consider therapeutic anticoagulation pending scan.";
    }

    return ClinicalScoreResult(
        score_name="Wells Criteria for Deep Vein Thrombosis",
        score=score,
        risk_level=risk,
        recommendation=rec,
        criteria_met=criteria
    );
}

def calculate_glasgow_coma_scale(eye: int, verbal: int, motor: int) -> ClinicalScoreResult {
    e = eye;
    v = verbal;
    m = motor;

    if e < 1 { e = 1; }
    if e > 4 { e = 4; }
    if v < 1 { v = 1; }
    if v > 5 { v = 5; }
    if m < 1 { m = 1; }
    if m > 6 { m = 6; }

    total = e + v + m;
    risk = "Mild Head Injury / Normal Consciousness (13-15)";
    rec = "Routine neurological observation. Hourly GCS checks if head trauma.";

    if total >= 9 and total <= 12 {
        risk = "Moderate Head Injury (9-12)";
        rec = "Urgent Non-Contrast CT Brain. Continuous ETU observation. Neurosurgical consult.";
    } elif total <= 8 {
        risk = "Severe Head Injury / Coma (3-8)";
        rec = "Immediate Airway Protection: Intubation indicated (GCS <= 8). Resuscitation bay protocol.";
    }

    criteria = [
        "Eye Response: " + str(e) + "/4",
        "Verbal Response: " + str(v) + "/5",
        "Motor Response: " + str(m) + "/6"
    ];

    return ClinicalScoreResult(
        score_name="Glasgow Coma Scale (GCS)",
        score=total,
        risk_level=risk,
        recommendation=rec,
        criteria_met=criteria
    );
}


# =====================================================================
# SRI LANKA NATIONAL FORMULARY PEDIATRIC DOSING CALCULATOR
# =====================================================================

def calculate_pediatric_dose(medication: str, weight_kg: float, age_months: int) -> PediatricDoseResult {
    med = medication.lower();
    wt = weight_kg;
    if wt <= 0.0 {
        wt = 10.0;
    }

    if "paracetamol" in med or "panadol" in med {
        single_dose = wt * 15.0;
        max_daily = wt * 60.0;
        if single_dose > 1000.0 {
            single_dose = 1000.0;
        }
        if max_daily > 4000.0 {
            max_daily = 4000.0;
        }

        return PediatricDoseResult(
            medication="Paracetamol Pediatric Syrup (120mg/5ml or 250mg/5ml)",
            weight_kg=wt,
            single_dose_mg=single_dose,
            frequency="Every 4-6 hours as needed for fever or pain (maximum 4 doses in 24 hours)",
            max_daily_dose_mg=max_daily,
            instructions="Maintain at least 4 hours between doses. Do not exceed 4 doses in 24 hours. Ensure patient is well hydrated."
        );
    }

    if "amoxicillin" in med {
        single_dose = (wt * 30.0) / 3.0;
        max_daily = wt * 50.0;
        if single_dose > 500.0 {
            single_dose = 500.0;
        }
        if max_daily > 1500.0 {
            max_daily = 1500.0;
        }

        return PediatricDoseResult(
            medication="Amoxicillin Pediatric Suspension (125mg/5ml or 250mg/5ml)",
            weight_kg=wt,
            single_dose_mg=single_dose,
            frequency="Three times daily (every 8 hours) for 5-7 days",
            max_daily_dose_mg=max_daily,
            instructions="Shake bottle well before administering. Complete the full prescribed course even if symptoms resolve."
        );
    }

    if "cetirizine" in med {
        single_dose = 2.5;
        if age_months >= 24 and age_months < 72 {
            single_dose = 2.5;
        } elif age_months >= 72 {
            single_dose = 5.0;
        }
        max_daily = single_dose * 2.0;

        return PediatricDoseResult(
            medication="Cetirizine Pediatric Solution (5mg/5ml)",
            weight_kg=wt,
            single_dose_mg=single_dose,
            frequency="Once daily at night (or twice daily for older children)",
            max_daily_dose_mg=max_daily,
            instructions="May cause mild drowsiness. Administer preferably before bedtime."
        );
    }

    if "salbutamol" in med or "ventolin" in med {
        single_dose = wt * 0.1;
        if single_dose < 1.0 {
            single_dose = 1.0;
        }
        if single_dose > 4.0 {
            single_dose = 4.0;
        }
        max_daily = single_dose * 4.0;

        return PediatricDoseResult(
            medication="Salbutamol Syrup (2mg/5ml) or Metered Dose Inhaler with Spacer",
            weight_kg=wt,
            single_dose_mg=single_dose,
            frequency="Three to four times daily as needed for wheezing",
            max_daily_dose_mg=max_daily,
            instructions="Use with age-appropriate aerochamber / spacer mask. If breathing difficulty worsens, bring immediately to ETU."
        );
    }

    # Default fallback
    return PediatricDoseResult(
        medication=medication,
        weight_kg=wt,
        single_dose_mg=wt * 5.0,
        frequency="Twice daily as instructed by medical officer",
        max_daily_dose_mg=wt * 20.0,
        instructions="Refer to the Sri Lanka National Formulary for exact pediatric dosing guidelines."
    );
}


# =====================================================================
# DRUG-DRUG INTERACTION & ALLERGY CHECKING ENGINE
# =====================================================================

def check_nlem_drug_interactions(drugs_prescribed: list) -> list {
    alerts = [];
    lower_drugs = [];
    for d in drugs_prescribed {
        lower_drugs.append(d.lower());
    }

    has_warfarin = False;
    has_nsaid = False;
    has_metformin = False;
    has_contrast = False;
    has_acei = False;
    has_spironolactone = False;
    has_clopidogrel = False;
    has_omeprazole = False;
    has_macrolide = False;
    has_statin = False;

    for d in lower_drugs {
        if "warfarin" in d or "coumadin" in d { has_warfarin = True; }
        if "aspirin" in d or "ibuprofen" in d or "diclofenac" in d or "mefenamic" in d { has_nsaid = True; }
        if "metformin" in d { has_metformin = True; }
        if "contrast" in d or "ct scan" in d { has_contrast = True; }
        if "enalapril" in d or "ramipril" in d or "lisinopril" in d or "losartan" in d { has_acei = True; }
        if "spironolactone" in d or "eplerenone" in d { has_spironolactone = True; }
        if "clopidogrel" in d or "plavix" in d { has_clopidogrel = True; }
        if "omeprazole" in d { has_omeprazole = True; }
        if "clarithromycin" in d or "erythromycin" in d { has_macrolide = True; }
        if "atorvastatin" in d or "simvastatin" in d { has_statin = True; }
    }

    if has_warfarin and has_nsaid {
        alerts.append({
            "drug_a": "Warfarin",
            "drug_b": "NSAID (Ibuprofen/Diclofenac/Aspirin)",
            "severity": "CRITICAL",
            "mechanism": "Synergistic inhibition of platelet aggregation and gastric mucosal erosion markedly elevating risk of severe gastrointestinal hemorrhage.",
            "clinical_action": "Avoid co-administration. Substitute with Paracetamol for analgesia. Monitor INR closely."
        });
    }

    if has_metformin and has_contrast {
        alerts.append({
            "drug_a": "Metformin",
            "drug_b": "Iodinated Radiocontrast Media",
            "severity": "HIGH",
            "mechanism": "Contrast-induced acute nephropathy can precipitate toxic metformin accumulation and fatal lactic acidosis.",
            "clinical_action": "Withhold Metformin on day of contrast scan and for 48 hours post-procedure until renal function is confirmed stable."
        });
    }

    if has_acei and has_spironolactone {
        alerts.append({
            "drug_a": "ACE-Inhibitor / ARB (Enalapril/Losartan)",
            "drug_b": "Spironolactone",
            "severity": "MODERATE",
            "mechanism": "Additive potassium retention leading to potentially lethal hyperkalemia.",
            "clinical_action": "Monitor Serum Potassium and Creatinine within 1-2 weeks of initiation and dose changes."
        });
    }

    if has_clopidogrel and has_omeprazole {
        alerts.append({
            "drug_a": "Clopidogrel",
            "drug_b": "Omeprazole",
            "severity": "MODERATE",
            "mechanism": "CYP2C19 competitive inhibition reduces active metabolite generation of clopidogrel, attenuating antiplatelet efficacy.",
            "clinical_action": "Consider Pantoprazole or Famotidine as safer alternative gastroprotective agents."
        });
    }

    if has_macrolide and has_statin {
        alerts.append({
            "drug_a": "Macrolide Antibiotic (Clarithromycin/Erythromycin)",
            "drug_b": "Statin (Simvastatin/Atorvastatin)",
            "severity": "HIGH",
            "mechanism": "CYP3A4 inhibition produces pronounced statin elevation, substantially escalating rhabdomyolysis risk.",
            "clinical_action": "Temporarily suspend statin therapy during macrolide antibiotic course."
        });
    }

    return alerts;
}

def check_allergy_cross_sensitivity(prescribed_drug: str, known_allergies: list) -> list {
    alerts = [];
    d = prescribed_drug.lower();

    for a in known_allergies {
        allg = a.lower();

        # Penicillin and Cephalosporin cross-allergy
        if "penicillin" in allg or "amoxicillin" in allg or "ampicillin" in allg or "augmentin" in allg {
            if "amoxicillin" in d or "ampicillin" in d or "co-amoxiclav" in d or "augmentin" in d or "cloxacillin" in d {
                alerts.append({
                    "drug": prescribed_drug,
                    "allergen": a,
                    "severity": "CRITICAL",
                    "cross_reactivity_pct": "100%",
                    "warning": "Direct penicillin group allergy contraindication. High risk of immediate anaphylaxis or severe urticaria."
                });
            } elif "cefalexin" in d or "ceftriaxone" in d or "cefuroxime" in d or "cefotaxime" in d {
                alerts.append({
                    "drug": prescribed_drug,
                    "allergen": a,
                    "severity": "WARNING",
                    "cross_reactivity_pct": "5-10%",
                    "warning": "Beta-lactam cephalosporin cross-reactivity warning. Use with extreme caution under medical supervision."
                });
            }
        }

        # Sulfa cross-allergy
        if "sulfa" in allg or "sulfamethoxazole" in allg or "bactrim" in allg or "co-trimoxazole" in allg {
            if "co-trimoxazole" in d or "bactrim" in d or "sulfasalazine" in d or "gliclazide" in d {
                alerts.append({
                    "drug": prescribed_drug,
                    "allergen": a,
                    "severity": "CRITICAL",
                    "cross_reactivity_pct": "High",
                    "warning": "Sulfonamide group cross-sensitivity. Risk of Stevens-Johnson syndrome (SJS) or drug eruption."
                });
            }
        }

        # NSAID / Aspirin cross-allergy
        if "aspirin" in allg or "nsaid" in allg or "ibuprofen" in allg {
            if "aspirin" in d or "ibuprofen" in d or "diclofenac" in d or "mefenamic" in d or "naproxen" in d or "ketoprofen" in d {
                alerts.append({
                    "drug": prescribed_drug,
                    "allergen": a,
                    "severity": "CRITICAL",
                    "cross_reactivity_pct": "High",
                    "warning": "NSAID-exacerbated respiratory disease (NERD) or anaphylactoid cross-reaction. Switch to paracetamol."
                });
            }
        }
    }

    return alerts;
}

def check_renal_adjustment_needed(drug_name: str, egfr_ml_min: float) -> dict {
    d = drug_name.lower();
    requires_adjustment = False;
    guideline = "Standard adult dosage applies.";

    if egfr_ml_min < 30.0 {
        if "metformin" in d {
            requires_adjustment = True;
            guideline = "CONTRAINDICATED when eGFR < 30 mL/min due to risk of lactic acidosis. Discontinue.";
        } elif "ciprofloxacin" in d {
            requires_adjustment = True;
            guideline = "Reduce dose by 50% or administer every 18-24 hours.";
        } elif "enalapril" in d or "ramipril" in d {
            requires_adjustment = True;
            guideline = "Initiate at low test dose (2.5mg) and titrate carefully with serum creatinine monitoring.";
        } elif "gentamicin" in d or "amikacin" in d {
            requires_adjustment = True;
            guideline = "Dose interval extension mandatory based on therapeutic drug monitoring (TDM) trough levels.";
        }
    } elif egfr_ml_min < 50.0 {
        if "metformin" in d {
            requires_adjustment = True;
            guideline = "Maximum daily dose 1000 mg (500 mg twice daily). Monitor eGFR every 3-6 months.";
        }
    }

    return {
        "drug_name": drug_name,
        "egfr_ml_min": egfr_ml_min,
        "requires_adjustment": requires_adjustment,
        "guideline": guideline
    };
}


# =====================================================================
# DETAILED 13-FACILITY PROTOCOL CATALOGUE
# =====================================================================

def get_facility_detailed_protocol(facility_key: str) -> FacilityProtocolResult {
    k = facility_key.lower();

    if "mri" in k {
        return FacilityProtocolResult(
            facility_key="fac-mri-01",
            name="Magnetic Resonance Imaging (MRI 1.5T)",
            modality="Radiology / Magnetic Resonance",
            prep_steps=[
                "Complete MRI Safety Questionnaire before entering magnet room",
                "Remove all metallic body ornaments, pins, wristwatches, and credit cards",
                "Fasting 4-6 hours if abdominal or pelvic examination",
                "Insert earplugs provided by technician before sequence start",
                "Remain completely still for 30-45 minutes"
            ],
            contraindications=[
                "Non-MRI conditional cardiac pacemakers or defibrillators",
                "Ferromagnetic intracranial aneurysm clips",
                "Cochlear implants",
                "Metallic foreign bodies in eye/orbit"
            ],
            required_labs=["Serum Creatinine & eGFR (if gadolinium contrast indicated)"],
            estimated_duration_mins=45,
            nursing_notes="Screen patient for claustrophobia. Pediatric patients may require mild sedation under anesthesiologist."
        );
    }

    if "ct" in k {
        return FacilityProtocolResult(
            facility_key="fac-ct-01",
            name="Computed Tomography (CT 128-Slice)",
            modality="Radiology / Computed Tomography",
            prep_steps=[
                "Fasting for 4 hours prior to scan",
                "Adequate oral water hydration pre and post scan",
                "Check cannula patency (18G or 20G in antecubital fossa for power injector)",
                "Review allergy history for iodinated contrast media"
            ],
            contraindications=[
                "Known severe anaphylaxis to iodinated contrast",
                "Pregnancy (relative contraindication - requires lead abdominal shielding if emergent)",
                "Severe renal failure (eGFR < 30) without planned hemodialysis"
            ],
            required_labs=["Serum Creatinine within 30 days", "eGFR"],
            estimated_duration_mins=15,
            nursing_notes="Withhold Metformin 48 hours post contrast in diabetic patients."
        );
    }

    if "xray" in k or "x-ray" in k {
        return FacilityProtocolResult(
            facility_key="fac-xray-01",
            name="Digital Radiography (X-Ray)",
            modality="Radiology / Plain Radiography",
            prep_steps=[
                "Remove metal jewelry and clothing with metal zippers/buttons",
                "Female patients must inform radiographer if possibility of pregnancy exists"
            ],
            contraindications=["Pregnancy (unless life-saving and with gonad shielding)"],
            required_labs=[],
            estimated_duration_mins=10,
            nursing_notes="Ensure standard radiation safety ALARA principles followed."
        );
    }

    if "ultrasound" in k or "uss" in k {
        return FacilityProtocolResult(
            facility_key="fac-uss-01",
            name="Diagnostic Ultrasonography",
            modality="Radiology / Ultrasound",
            prep_steps=[
                "Abdominal scan: Fasting 6 hours to minimize bowel gas",
                "Pelvic scan: Drink 1 liter water 1 hour prior to maintain full bladder",
                "Wear comfortable two-piece clothing"
            ],
            contraindications=["None (Non-ionizing radiation)"],
            required_labs=[],
            estimated_duration_mins=20,
            nursing_notes="Water-soluble acoustic coupling gel used. Wipe off with paper towel."
        );
    }

    if "mammo" in k {
        return FacilityProtocolResult(
            facility_key="fac-mammo-01",
            name="Digital Mammography",
            modality="Radiology / Breast Imaging",
            prep_steps=[
                "Schedule during week following menstrual period when breasts are least tender",
                "Do not use deodorants, antiperspirants, or talcum powder on morning of exam",
                "Wear a separate top and skirt/trousers"
            ],
            contraindications=["Pregnancy (use ultrasound instead)"],
            required_labs=[],
            estimated_duration_mins=20,
            nursing_notes="Mild compression required for optimal diagnostic image resolution."
        );
    }

    if "ecg" in k {
        return FacilityProtocolResult(
            facility_key="fac-ecg-01",
            name="12-Lead Electrocardiography (ECG)",
            modality="Cardiology / Diagnostic",
            prep_steps=[
                "Rest quietly in supine position for 5-10 minutes prior to recording",
                "Avoid energetic physical exercise or caffeinated beverages right before test",
                "Expose chest, wrists, and ankles for electrode placement"
            ],
            contraindications=["None"],
            required_labs=[],
            estimated_duration_mins=10,
            nursing_notes="Shave excessive chest hair if necessary for reliable electrode adhesion."
        );
    }

    if "echo" in k {
        return FacilityProtocolResult(
            facility_key="fac-echo-01",
            name="Transthoracic Echocardiography (Echo)",
            modality="Cardiology / Ultrasound",
            prep_steps=[
                "Continue all usual cardiac medications unless instructed otherwise",
                "Wear comfortable two-piece clothing",
                "No fasting required"
            ],
            contraindications=["None"],
            required_labs=[],
            estimated_duration_mins=30,
            nursing_notes="Patient positioned in left lateral decubitus position."
        );
    }

    if "lab" in k or "blood" in k {
        return FacilityProtocolResult(
            facility_key="fac-lab-01",
            name="Central Clinical Pathology Laboratory",
            modality="Laboratory / Phlebotomy",
            prep_steps=[
                "Fasting tests (FBS, Lipid): Strict 8-10h overnight fasting",
                "Routine tests (FBC, UFR): No fasting required",
                "Collect midstream urine sample in sterile container"
            ],
            contraindications=["None"],
            required_labs=[],
            estimated_duration_mins=10,
            nursing_notes="Apply firm pressure to venipuncture site for 2 minutes to prevent hematoma."
        );
    }

    if "endo" in k or "ogd" in k {
        return FacilityProtocolResult(
            facility_key="fac-endo-01",
            name="Gastrointestinal Endoscopy Unit",
            modality="Gastroenterology / Interventional",
            prep_steps=[
                "Strict fasting for 8 hours prior to procedure",
                "Do not take morning medications without consulting gastroenterology team",
                "Must arrange an accompanying adult escort for transport home",
                "Do not drive or operate machinery for 12 hours post-sedation"
            ],
            contraindications=[
                "Suspected gastrointestinal perforation",
                "Severe cardiopulmonary instability",
                "Inability to provide informed consent"
            ],
            required_labs=["Coagulation profile (PT/INR) if biopsy anticipated", "FBC"],
            estimated_duration_mins=45,
            nursing_notes="Local lidocaine pharyngeal spray administered prior to scope introduction."
        );
    }

    if "dial" in k {
        return FacilityProtocolResult(
            facility_key="fac-dial-01",
            name="Hemodialysis Unit",
            modality="Nephrology / Renal Replacement Therapy",
            prep_steps=[
                "Record pre-dialysis weight and sitting/standing blood pressure",
                "Wash AV fistula arm thoroughly with antiseptic soap before cannulation",
                "Take morning phosphate binders with light meal"
            ],
            contraindications=["Severe refractory hypotension unresponsive to inotropes"],
            required_labs=["Pre and Post BUN", "Serum Potassium", "Hemoglobin"],
            estimated_duration_mins=240,
            nursing_notes="Strict aseptic technique during AV fistula cannulation. Monitor for dysequilibrium syndrome."
        );
    }

    if "physio" in k {
        return FacilityProtocolResult(
            facility_key="fac-phys-01",
            name="Physiotherapy and Rehabilitation Unit",
            modality="Rehabilitation Medicine",
            prep_steps=[
                "Wear loose non-restrictive sportswear and athletic shoes",
                "Bring previous orthopaedic X-rays and surgical discharge summaries",
                "Take prescribed pain medication 30 minutes before session if severe pain"
            ],
            contraindications=[
                "Unstable spinal fractures",
                "Acute deep vein thrombosis without anticoagulation",
                "Acute myocardial infarction within 48 hours"
            ],
            required_labs=[],
            estimated_duration_mins=45,
            nursing_notes="Assess baseline mobility and pain score on visual analogue scale (0-10)."
        );
    }

    if "pharm" in k {
        return FacilityProtocolResult(
            facility_key="fac-pharm-01",
            name="Outpatient Pharmacy",
            modality="Pharmacy / Dispensing",
            prep_steps=[
                "Present valid digital prescription token or clinic slip",
                "Verify name, age, and known drug allergies at dispensing counter",
                "Listen carefully to pharmacist counselling on dosage schedules"
            ],
            contraindications=[],
            required_labs=[],
            estimated_duration_mins=15,
            nursing_notes="Ensure patient receives clear dosage labels in their preferred language (Sinhala/Tamil/English)."
        );
    }

    # Default fallback to ETU
    return FacilityProtocolResult(
        facility_key="fac-etu-01",
        name="Emergency & Trauma Unit (ETU)",
        modality="Emergency Medicine",
        prep_steps=[
            "Immediate registration by triage nursing officer",
            "Triage category assigned based on Manchester Triage System",
            "Continuous vital sign monitoring (BP, Pulse, SpO2, ECG, Temp)"
        ],
        contraindications=[],
        required_labs=["Stat FBC", "Stat ECG", "Stat Blood Glucose"],
        estimated_duration_mins=60,
        nursing_notes="Immediate resuscitation takes precedence over administrative documentation."
    );
}


# =====================================================================
# MATERNAL & OBSTETRIC TRIAGE DECISION ENGINE
# =====================================================================

def evaluate_maternal_triage(
    gestational_weeks: int,
    sbp: int,
    dbp: int,
    proteinuria: bool,
    severe_headache_or_visual: bool,
    pv_bleeding: bool,
    reduced_fetal_movement: bool
) -> dict {
    triage_level = "Routine Antenatal Clinic";
    is_emergency = False;
    action = "Continue standard antenatal care schedule and iron/folate supplementation.";
    admit_ward = "Antenatal Clinic OPD";

    if pv_bleeding {
        triage_level = "Obstetric Red Emergency";
        is_emergency = True;
        action = "Suspected Placenta Praevia / Abruptio Placentae. Stat IV line 16G, crossmatch 2 units blood, urgent Obstetric MO consult.";
        admit_ward = "Labour Room / Obstetric High Dependency Unit";
    } elif sbp >= 160 or dbp >= 110 or (sbp >= 140 and proteinuria and severe_headache_or_visual) {
        triage_level = "Severe Preeclampsia / Imminent Eclampsia Alert";
        is_emergency = True;
        action = "Administer Magnesium Sulphate loading dose (Pritchard regimen) and oral Nifedipine 10mg stat. Dim quiet room.";
        admit_ward = "Obstetric High Dependency Unit (HDU)";
    } elif sbp >= 140 or dbp >= 90 {
        triage_level = "Gestational Hypertension";
        action = "Order 24-hour urine protein or urine PCR, liver enzymes, and uric acid. Review within 48 hours.";
        admit_ward = "Antenatal Ward 12";
    } elif reduced_fetal_movement and gestational_weeks >= 28 {
        triage_level = "Urgent Fetal Well-being Assessment";
        action = "Perform immediate Cardiotocography (CTG) 30-minute trace and ultrasound for Biophysical Profile (BPP).";
        admit_ward = "Maternity Assessment Suite";
    }

    return {
        "gestational_weeks": gestational_weeks,
        "triage_level": triage_level,
        "is_emergency": is_emergency,
        "action": action,
        "admit_ward": admit_ward
    };
}


# =====================================================================
# SRI LANKA SNAKEBITE ENVENOMATION PROTOCOL
# =====================================================================

def evaluate_snakebite_protocol(
    bite_marks: bool,
    local_swelling_beyond_joint: bool,
    incoagulable_blood_20wbct: bool,
    ptosis_or_neuro: bool,
    oliguria_or_dark_urine: bool
) -> dict {
    antivenom_indicated = False;
    triage_priority = "OPD Observation";
    syndrome = "Dry Bite / Non-venomous";
    clinical_instructions = "Clean puncture site with soap and water. Administer Tetanus Toxoid 0.5ml IM if indicated. Repeat 20WBCT every 30 minutes for 3 hours, then hourly for 24 hours.";

    if incoagulable_blood_20wbct or ptosis_or_neuro or oliguria_or_dark_urine {
        antivenom_indicated = True;
        triage_priority = "Red (Emergency Treatment Unit)";
        
        if incoagulable_blood_20wbct {
            syndrome = "Systemic Envenomation - Hemotoxic (Russell's Viper / Saw-scaled Viper)";
            clinical_instructions = "Indications for Polyvalent Antivenom Serum (AVS) met. Dilute 10 vials in 200ml Normal Saline, infuse over 1 hour under close anaphylaxis monitoring (Adrenaline ready at bedside). Repeat 20WBCT at 6 hours.";
        } elif ptosis_or_neuro {
            syndrome = "Systemic Envenomation - Neurotoxic (Common Krait / Cobra)";
            clinical_instructions = "High risk of sudden respiratory paralysis. Administer 10 vials AVS. Atropine 0.6mg + Neostigmine 1.5mg trial. Prepare for mechanical ventilation / ICU transfer.";
        } elif oliguria_or_dark_urine {
            syndrome = "Acute Kidney Injury Secondary to Hemolysis / Rhabdomyolysis";
            clinical_instructions = "Urgent nephrology consult. Vigorous IV hydration with Normal Saline, target urine output > 100 ml/hr. Monitor serum potassium.";
        }
    } elif local_swelling_beyond_joint {
        triage_priority = "Yellow (Urgent Inward Admission)";
        syndrome = "Severe Local Envenomation (Hump-nosed Pit Viper / Merrem's)";
        clinical_instructions = "Elevate limb. Do not incise, suction, or apply tourniquet. Serial circumference measurements every 2 hours.";
    }

    return {
        "bite_marks": bite_marks,
        "triage_priority": triage_priority,
        "syndrome": syndrome,
        "antivenom_indicated": antivenom_indicated,
        "clinical_instructions": clinical_instructions
    };
}


# =====================================================================
# ACUTE ASTHMA EXACERBATION SEVERITY GRADING
# =====================================================================

def evaluate_asthma_severity(
    pefr_percent: float,
    can_complete_sentences: bool,
    pulse_rate: int,
    respiratory_rate: int,
    spo2_percent: float
) -> dict {
    severity = "Mild to Moderate Asthma";
    route = "OPD Nebulization Area";
    immediate_treatment = "Salbutamol 5mg + Ipratropium 0.5mg nebulization via oxygen 6-8 L/min. Oral Prednisolone 40mg.";
    transfer_icu = False;

    if spo2_percent < 92.0 or pefr_percent < 33.0 or pulse_rate > 130 or respiratory_rate > 30 or (not can_complete_sentences) {
        severity = "Severe Acute Asthma";
        route = "Emergency Treatment Unit (ETU)";
        immediate_treatment = "High-flow oxygen (target SpO2 94-98%). Back-to-back Salbutamol 5mg nebulizations every 20 minutes for 3 doses. IV Hydrocortisone 200mg stat. IV Magnesium Sulphate 2g infusion over 20 minutes.";
    }

    if spo2_percent < 90.0 and pefr_percent < 30.0 {
        severity = "Life-Threatening Asthma / Silent Chest";
        route = "ETU Resuscitation Bay / ICU";
        immediate_treatment = "Call Anaesthetic Medical Officer immediately. Prepare rapid sequence intubation. Continuous nebulization, IV Aminophylline / Adrenaline standby.";
        transfer_icu = True;
    }

    return {
        "severity": severity,
        "route": route,
        "immediate_treatment": immediate_treatment,
        "transfer_icu": transfer_icu,
        "target_spo2": "94 - 98%"
    };
}


# =====================================================================
# OFFICIAL TRILINGUAL LOCALIZATION (SINHALA / TAMIL / ENGLISH)
# =====================================================================

def get_trilingual_strings(lang: str) -> dict {
    l = lang.lower();
    if l == "si" {
        return {
            "lang": "si",
            "lang_name": "සිංහල",
            "brand_title": "ස්මාර්ට් රෝහල් OPD පද්ධතිය",
            "brand_sub": "ශ්‍රී ලංකා සෞඛ්‍ය අමාත්‍යාංශය — බාහිර රෝගී අංශ ඩිජිටල් සේවාව",
            "nav_directory": "🗺️ රෝහල් නාමාවලිය",
            "nav_checkin": "📲 රෝගී ලියාපදිංචිය",
            "nav_doctor": "👨‍⚕️ වෛද්‍ය පුවරුව",
            "nav_staff": "🏥 කාර්ය මණ්ඩලය / වාට්ටු",
            "btn_signin": "🔑 පිවිසෙන්න",
            "btn_signout": "🚪 ඉවත් වන්න",
            "dir_title": "🗺️ දිවයින පුරා රජයේ රෝහල් ජාලය",
            "dir_sub": "විශේෂඥ වෛද්‍ය පහසුකම්, ඇඳන් සංඛ්‍යාව සහ සජීවී OPD පෝලිම් ධාරිතාව සහිත නිල තොරතුරු.",
            "search_ph": "රෝහලේ නම, දිස්ත්‍රික්කය හෝ නගරය සොයන්න...",
            "all_provinces": "සියලුම පළාත් (දිවයින පුරා)",
            "all_facilities": "සියලුම වෛද්‍ය පහසුකම්",
            "btn_locate": "📍 මට ආසන්න රෝහල් (කොළඹ)",
            "btn_details": "🏥 විස්තර සහ පහසුකම්",
            "btn_map": "🗺️ සිතියම බලන්න",
            "free_beds": "හිස් ඇඳන්",
            "total_beds": "මුළු ඇඳන්",
            "opd_queue": "OPD පෝලිම",
            "opd_hours": "OPD වේලාවන්",
            "specialists": "විශේෂඥ වෛද්‍යවරු",
            "checkin_badge": "📲 QR රෝගී ස්වයං ලියාපදිංචිය",
            "checkin_title": "රෝහල් ප්‍රවේශ ලියාපදිංචිය සහ මඟපෙන්වන සායනික වර්ගීකරණය",
            "checkin_sub": "AI සහායක වර්ගීකරණය — සියලු නිර්දේශ බලපත්‍රලාභී වෛද්‍ය නිලධාරීන් විසින් තහවුරු කරනු ලැබේ",
            "step1_title": "🏥 පියවර 1: රෝගී අනන්‍යතාව සහ දත්ත එකඟතාව (PDPA)",
            "lbl_hospital": "තෝරාගත් රෝහල",
            "lbl_fullname": "සම්පූර්ණ නම",
            "lbl_nic": "ජාතික හැඳුනුම්පත් අංකය (NIC)",
            "lbl_phone": "ජංගම දුරකථන අංකය (OTP සහ ඩිජිටල් ටෝකනය සඳහා)",
            "lbl_age": "වයස",
            "lbl_gender": "ස්ත්‍රී / පුරුෂ භාවය",
            "male": "පුරුෂ",
            "female": "ස්ත්‍රී",
            "other": "වෙනත්",
            "lbl_consent": "2022 අංක 9 දරන ශ්‍රී ලංකා පුද්ගලික දත්ත ආරක්ෂණ (PDPA) පනත යටතේ මගේ රෝග ලක්ෂණ සහ දත්ත රෝහල් වර්ගීකරණය සඳහා තාවකාලිකව සැකසීමට මම එකඟ වෙමි.",
            "step2_title": "🩺 පියවර 2: AI මඟපෙන්වන රෝග ලක්ෂණ ප්‍රශ්නාවලිය",
            "symptom_ph": "ඔබගේ ප්‍රධාන රෝග ලක්ෂණ මෙහි සටහන් කරන්න (උදා: පපුවේ තද කැක්කුම, දින 3ක උණ, හිසරදය, දණහිසේ වේදනාව)...",
            "btn_triage": "⚡ සායනික වර්ගීකරණය කර අංකය ලබාගන්න",
            "quick_sym_title": "නිතර වාර්තා වන රෝග ලක්ෂණ තෝරන්න:",
            "sym_chest": "පපුවේ තද කැක්කුම (හදිසි ප්‍රතිකාර)",
            "sym_fever": "තද උණ සහ සන්ධි වේදනාව (ඩෙංගු සැකය)",
            "sym_pressure": "අධික රුධිර පීඩනය සහ කරකැවිල්ල",
            "sym_child": "කුඩා දරුවාගේ කැස්ස සහ හතිය",
            "health_title": "මගේ සෞඛ්‍ය පැතිකඩ සහ වෛද්‍ය වාර්තා",
            "tab_cond": "පවතින රෝග",
            "tab_vit": "ශරීර සලකුණු (විටල්ස්)",
            "tab_all": "ඖෂධ ආසාත්මිකතා (ඇලජි)",
            "tab_med": "වත්මන් ඖෂධ",
            "tab_lab": "රසායනාගාර වාර්තා",
            "tab_his": "රෝහල් ඉතිහාසය",
            "tab_prep": "පරීක්ෂණ සහ පූර්ව සූදානම",
            "emergency_alert": "අත්‍යවශ්‍ය හදිසි අනතුරු ඇඟවීමයි",
            "emergency_desc": "රෝග ලක්ෂණ අනුව රෝගියා වහාම හදිසි ප්‍රතිකාර ඒකකයට (ETU) යොමු කළ යුතුය.",
            "queue_token": "ඩිජිටල් පෝලිම් අංකය",
            "wait_time": "ඇස්තමේන්තුගත පොරොත්තු කාලය",
            "mins": "මිනිත්තු",
            "disclaimer": "මෙම තොරතුරු රෝහල් පද්ධතියෙන් සපයන මාර්ගෝපදේශයක් පමණි. වෛද්‍ය උපදෙස් සඳහා වෛද්‍යවරයකු හමුවන්න."
        };
    }

    if l == "ta" {
        return {
            "lang": "ta",
            "lang_name": "தமிழ்",
            "brand_title": "ஸ்மார்ட் மருத்துவமனை OPD முறைமை",
            "brand_sub": "இலங்கை சுகாதார அமைச்சு — வெளிநோயாளி பிரிவு டிஜிட்டல் சேவை",
            "nav_directory": "🗺️ மருத்துவமனை அடைவு",
            "nav_checkin": "📲 நோயாளி பதிவு",
            "nav_doctor": "👨‍⚕️ மருத்துவர் பலகை",
            "nav_staff": "🏥 ஊழியர் / வார்டு",
            "btn_signin": "🔑 உள்நுழைக",
            "btn_signout": "🚪 வெளியேறுக",
            "dir_title": "🗺️ நாடளாவிய அரச மருத்துவமனை வலையமைப்பு",
            "dir_sub": "சிறப்பு மருத்துவ வசதிகள், படுக்கை எண்ணிக்கை மற்றும் நேரடி OPD வரிசை திறன் கொண்ட உத்தியோகபூர்வ தகவல்கள்.",
            "search_ph": "மருத்துவமனை பெயர், மாவட்டம் அல்லது நகரைத் தேடுங்கள்...",
            "all_provinces": "அனைத்து மாகாணங்களும் (நாடளாவிய)",
            "all_facilities": "அனைத்து மருத்துவ வசதிகளும்",
            "btn_locate": "📍 அருகில் உள்ளவை (கொழும்பு)",
            "btn_details": "🏥 விவரங்கள் & வசதிகள்",
            "btn_map": "🗺️ வரைபடத்தைக் காண்க",
            "free_beds": "வெற்றிட படுக்கைகள்",
            "total_beds": "மொத்த படுக்கைகள்",
            "opd_queue": "OPD வரிசை",
            "opd_hours": "OPD நேரங்கள்",
            "specialists": "சிறப்பு மருத்துவர்கள்",
            "checkin_badge": "📲 QR நோயாளி சுய பதிவு",
            "checkin_title": "நுழைவு பதிவு மற்றும் வழிகாட்டப்பட்ட மருத்துவ வகைப்படுத்தல்",
            "checkin_sub": "AI உதவியுடன் வகைப்படுத்தல் — அனைத்து பரிந்துரைகளும் உரிமம் பெற்ற மருத்துவ அதிகாரிகளால் சரிபார்க்கப்படும்",
            "step1_title": "🏥 படி 1: நோயாளி அடையாளம் & தரவு ஒப்புதல் (PDPA)",
            "lbl_hospital": "தேர்ந்தெடுக்கப்பட்ட மருத்துவமனை",
            "lbl_fullname": "முழு பெயர்",
            "lbl_nic": "தேசிய அடையாள அட்டை (NIC)",
            "lbl_phone": "கைபேசி எண் (OTP மற்றும் டிஜிட்டல் டோக்கனுக்கு)",
            "lbl_age": "வயது",
            "lbl_gender": "பாலினம்",
            "male": "ஆண்",
            "female": "பெண்",
            "other": "மற்றவை",
            "lbl_consent": "2022 ஆம் ஆண்டின் 9 ஆம் இலக்க இலங்கை தனிநபர் தரவு பாதுகாப்பு (PDPA) சட்டத்தின் கீழ் எனது அறிகுறிகள் மற்றும் தரவை தற்காலிகமாக செயலாக்க ஒப்புக்கொள்கிறேன்.",
            "step2_title": "🩺 படி 2: AI வழிகாட்டப்பட்ட அறிகுறி வினாத்தாள்",
            "symptom_ph": "உங்கள் முக்கிய அறிகுறிகளை இங்கே விவரிக்கவும் (எ.கா. நெஞ்சு வலி, 3 நாட்களாக காய்ச்சல், தலைவலி, மூட்டு வலி)...",
            "btn_triage": "⚡ வகைப்படுத்தல் செய்து டோக்கன் பெறுக",
            "quick_sym_title": "அடிக்கடி காணப்படும் அறிகுறிகளைத் தேர்ந்தெடுக்கவும்:",
            "sym_chest": "கடுமையான நெஞ்சு வலி (அவசர சிகிச்சை)",
            "sym_fever": "காய்ச்சல் மற்றும் மூட்டு வலி (டெங்கு சந்தேகம்)",
            "sym_pressure": "இரத்த அழுத்தம் மற்றும் தலைச்சுற்றல்",
            "sym_child": "குழந்தைக்கு இருமல் மற்றும் மூச்சுத்திணறல்",
            "health_title": "எனது சுகாதார விவரக்குறிப்பு & மருத்துவ பதிவுகள்",
            "tab_cond": "செயலில் உள்ள நோய்கள்",
            "tab_vit": "உடல் நல்வாழ்வு அளவீடுகள்",
            "tab_all": "மருந்து ஒவ்வாமைகள்",
            "tab_med": "தற்போதைய மருந்துகள்",
            "tab_lab": "ஆய்வக அறிக்கைகள்",
            "tab_his": "வருகை வரலாறு",
            "tab_prep": "பரிசோதனை மற்றும் தயார்படுத்தல்",
            "emergency_alert": "முக்கிய அவசர எச்சரிக்கை",
            "emergency_desc": "அறிகுறிகளின்படி நோயாளி உடனடியாக அவசர சிகிச்சை பிரிவுக்கு (ETU) அனுப்பப்பட வேண்டும்.",
            "queue_token": "டிஜிட்டல் வரிசை எண்",
            "wait_time": "மதிப்பிடப்பட்ட காத்திருப்பு நேரம்",
            "mins": "நிமிடங்கள்",
            "disclaimer": "இந்த தகவல் மருத்துவமனை அமைப்பின் வழிகாட்டுதல் மட்டுமே. மருத்துவ ஆலோசனைக்கு மருத்துவரை அணுகவும்."
        };
    }

    # Default to English
    return {
        "lang": "en",
        "lang_name": "English",
        "brand_title": "Smart Hospital OPD",
        "brand_sub": "Ministry of Health Sri Lanka — Outpatient Department Digital Services",
        "nav_directory": "🗺️ Public Directory",
        "nav_checkin": "📲 Patient Check-In",
        "nav_doctor": "👨‍⚕️ Doctor Dashboard",
        "nav_staff": "🏥 Staff / Ward",
        "btn_signin": "🔑 Sign In",
        "btn_signout": "🚪 Sign Out",
        "dir_title": "🗺️ Islandwide Government Hospital Network",
        "dir_sub": "Official geo-coordinates with specialty indicators, bed capacities, and live OPD queue numbers.",
        "search_ph": "Search hospital name, district, or city...",
        "all_provinces": "All Provinces (Islandwide)",
        "all_facilities": "All Medical Facilities",
        "btn_locate": "📍 Near Me (Colombo)",
        "btn_details": "🏥 View Details & Facilities",
        "btn_map": "🗺️ View Map",
        "free_beds": "Free Beds",
        "total_beds": "Total Beds",
        "opd_queue": "OPD Queue",
        "opd_hours": "OPD Hours",
        "specialists": "Specialists",
        "checkin_badge": "📲 QR Patient Self Check-In",
        "checkin_title": "Entrance Check-In & Guided Clinical Triage",
        "checkin_sub": "AI-assisted triage — all recommendations verified by licensed medical officers",
        "step1_title": "🏥 Step 1: Patient Identity & PDPA Consent",
        "lbl_hospital": "Selected Hospital",
        "lbl_fullname": "Full Name",
        "lbl_nic": "National Identity Card (NIC)",
        "lbl_phone": "Mobile Phone (for OTP & Digital Token)",
        "lbl_age": "Age",
        "lbl_gender": "Gender",
        "male": "Male",
        "female": "Female",
        "other": "Other",
        "lbl_consent": "I consent to clinical triage and temporary processing under Sri Lanka PDPA No. 9 of 2022.",
        "step2_title": "🩺 Step 2: AI Guided Symptom Questionnaire",
        "symptom_ph": "Describe your main symptoms (e.g. chest pain, cough for 3 days, fever, knee pain)...",
        "btn_triage": "⚡ Run Clinical Triage & Get Token",
        "quick_sym_title": "Quick Select Common Clinical Presentations:",
        "sym_chest": "Severe Chest Pain (Emergency)",
        "sym_fever": "Dengue Fever with Joint Pain",
        "sym_pressure": "Chronic Hypertension Follow-up",
        "sym_child": "Paediatric Cough & Wheezing",
        "health_title": "My Health Profile & Clinical Record",
        "tab_cond": "Active Conditions",
        "tab_vit": "Vital Signs & Trends",
        "tab_all": "Known Drug Allergies",
        "tab_med": "Current Prescriptions",
        "tab_lab": "Lab Results",
        "tab_his": "Visit History",
        "tab_prep": "Tests & Preparation",
        "emergency_alert": "CRITICAL EMERGENCY ALERT",
        "emergency_desc": "Patient requires immediate evaluation in the Emergency Treatment Unit (ETU).",
        "queue_token": "Digital Queue Token",
        "wait_time": "Estimated Wait Time",
        "mins": "minutes",
        "disclaimer": "This summary comes from your hospital record. It is guidance only, not a diagnosis."
    };
}

