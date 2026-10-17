"""Automated test suite for Sri Lanka Smart Hospital OPD System.

Tests:
1. Red-Flag Emergency Triage Safety Logic (Deterministic check)
2. Test Preparation Rules Table
3. Specialty Rule Engine
4. Master Data Seeding, Multi-Hospital Directory & Facilities
5. Patient Check-In and Virtual Queue Management
6. Role-Based Authentication & PDPA Consent Verification
7. Healthcare Facilities Catalog (13 facilities, MRI, CT, Prep instructions, Nurse update status)
8. Patient Health Records, Vitals Logging, and Doctor Prescribing with Allergy Guard
9. Doctor Profile Security (Public view strictly omits internal credentials)
"""

import from model {
    Hospital, Doctor, Facility, Patient, QueueSlot, Ward, Bed, AuditLog, AIOverrideLog
}
import from rules {
    check_red_flags, get_test_preparation, match_specialty_rule,
    get_facility_detailed_protocol, evaluate_dengue_guidelines,
    calculate_curb65, calculate_wells_dvt, calculate_glasgow_coma_scale,
    calculate_pediatric_dose, check_nlem_drug_interactions,
    check_allergy_cross_sensitivity, check_renal_adjustment_needed,
    evaluate_maternal_triage, evaluate_snakebite_protocol, evaluate_asthma_severity,
    get_trilingual_strings
}
import from walkers {
    InitMasterData, HospitalDirectory, CheckIn, Triage,
    AssignDoctor, JoinQueue, AdvanceQueue, Prescribe, AdmitPatient,
    AuthPatientStep1, AuthPatientStep2, AuthDoctor, AuthStaff, SignOut,
    GetPatientHealth, LogPatientVitals, GetHospitalFacilities, ManageFacility,
    DoctorTriageAction, DoctorPrescribeWithAllergyCheck, GetDoctorPublicProfile,
    GetAuditLogs, GetAIOverrides, GetI18nStrings
}

test "1. Red-Flag Emergency Triage Safety Logic" {
    # Test chest pain detection (Cardiac emergency)
    rf_chest = check_red_flags("Patient has acute chest pain and sweating");
    assert rf_chest.is_red_flag == True;
    assert rf_chest.triage_level == "Red (Emergency)";
    assert "ETU" in rf_chest.route;

    # Test breathing difficulty
    rf_breath = check_red_flags("severe difficulty breathing since morning");
    assert rf_breath.is_red_flag == True;
    assert rf_breath.triage_level == "Red (Emergency)";

    # Test Sinhala chest pain phrase
    rf_sin = check_red_flags("පපුවේ කැක්කුම සහ අමාරුයි");
    assert rf_sin.is_red_flag == True;

    # Test routine symptom (non-emergency)
    rf_routine = check_red_flags("Mild runny nose and headache for 2 days");
    assert rf_routine.is_red_flag == False;
    assert rf_routine.triage_level == "Green (Routine)";
}

test "2. Test Preparation Rules Table" {
    fbs_prep = get_test_preparation("Fasting Blood Sugar");
    assert "8-10 hours" in fbs_prep.instructions;
    assert "Room 4" in fbs_prep.location;

    uss_prep = get_test_preparation("Ultrasound Abdomen");
    assert "full bladder" in uss_prep.instructions;

    ecg_prep = get_test_preparation("12-Lead ECG");
    assert "quietly" in ecg_prep.instructions;
}

test "3. Specialty Rule Engine" {
    # Paediatric rule by age
    spec_child = match_specialty_rule("fever and cough", 6, "Male");
    assert spec_child == "Paediatrics";

    # Adult ENT
    spec_ent = match_specialty_rule("ear pain and difficulty hearing", 35, "Female");
    assert spec_ent == "ENT (Otolaryngology)";

    # Adult Cardiology
    spec_cardio = match_specialty_rule("palpitation and high blood pressure", 55, "Male");
    assert spec_cardio == "Cardiology";

    # Orthopaedics
    spec_ortho = match_specialty_rule("knee pain and ankle joint swelling", 45, "Female");
    assert spec_ortho == "Orthopaedics";
}

test "4. Master Data Seeding and Hospital Directory Walkers" {
    init_res = root spawn InitMasterData(data_path="data/sri_lanka_hospitals.json");
    assert len(init_res.reports) > 0;
    
    dir_res = root spawn HospitalDirectory();
    assert len(dir_res.reports) > 0;
    hospitals = dir_res.reports[0].get("hospitals", []);
    assert len(hospitals) >= 10;

    west_res = root spawn HospitalDirectory(province="Western");
    west_hospitals = west_res.reports[0].get("hospitals", []);
    assert len(west_hospitals) >= 3;
}

test "5. Patient Check-In and Virtual Queue Management" {
    checkin_res = root spawn CheckIn(
        hospital_id="hosp-nhsl-01",
        name="Kasun Bandara",
        phone="0771234567",
        age=34,
        sex="Male",
        nic="199215001234",
        consent=True,
        symptoms="recurring palpitations and rapid heartbeat"
    );
    assert len(checkin_res.reports) > 0;
    assert checkin_res.reports[0].get("ok") == True;
    pat_id = checkin_res.reports[0].get("patient_id", "");

    triage_res = root spawn Triage(
        symptoms="recurring palpitations and rapid heartbeat",
        age=34,
        sex="Male"
    );
    assert len(triage_res.reports) > 0;
    rec_spec = triage_res.reports[0].get("assigned_specialty", "");
    assert rec_spec == "Cardiology";

    assign_res = root spawn AssignDoctor(
        hospital_id="hosp-nhsl-01",
        specialty_name=rec_spec
    );
    assert len(assign_res.reports) > 0;
    doc_id = assign_res.reports[0].get("doctor_id", "");
    assert doc_id != "";

    queue_res = root spawn JoinQueue(
        hospital_id="hosp-nhsl-01",
        doctor_id=doc_id,
        patient_id=pat_id,
        patient_name="Kasun Bandara"
    );
    assert len(queue_res.reports) > 0;
    ticket = queue_res.reports[0];
    assert ticket.get("ok") == True;
    assert ticket.get("ticket_number") >= 1;
    assert ticket.get("state") == "front";

    adv_res = root spawn AdvanceQueue(doctor_id=doc_id, action="call_next");
    assert len(adv_res.reports) > 0;
    q_state = adv_res.reports[0].get("queue", []) as list;
    has_in_room = False;
    for slot in q_state {
        slot_dict = slot as dict;
        if slot_dict.get("state") == "in_room" {
            has_in_room = True;
            break;
        }
    }
    assert has_in_room == True;

    rx_res = root spawn Prescribe(
        patient_id=pat_id,
        patient_name="Kasun Bandara",
        doctor_id=doc_id,
        doctor_name="Dr. Priyantha Senaratne",
        items="Atenolol 25mg daily, Aspirin 75mg daily"
    );
    assert len(rx_res.reports) > 0;
    assert rx_res.reports[0].get("ok") == True;
    assert rx_res.reports[0].get("status") == "sent";
}

test "6. Role-Based Authentication & PDPA Consent Verification" {
    # 1. Patient Step 1: Request OTP
    p_step1 = root spawn AuthPatientStep1(phone="0771234567", nic="199215001234", hospital_id="hosp-nhsl-01");
    assert len(p_step1.reports) > 0;
    assert p_step1.reports[0].get("ok") == True;
    assert p_step1.reports[0].get("step") == 2;
    otp = p_step1.reports[0].get("otp_hint", "");

    # 2. Patient Step 2: Verification requires consent
    p_fail = root spawn AuthPatientStep2(phone="0771234567", otp=otp, consent=False);
    assert p_fail.reports[0].get("ok") == False;

    # 3. Patient Step 2: Successful verification with consent
    p_step2 = root spawn AuthPatientStep2(phone="0771234567", otp=otp, consent=True);
    assert p_step2.reports[0].get("ok") == True;
    assert p_step2.reports[0].get("role") == "patient";
    assert "jwt-pat" in p_step2.reports[0].get("token", "");

    # 4. Doctor Login: Email + Password (Hospital and specialty automatically derived)
    doc_login = root spawn AuthDoctor(email="priyantha.s@example.lk", password="doctor123");
    assert doc_login.reports[0].get("ok") == True;
    assert doc_login.reports[0].get("role") == "doctor";
    assert doc_login.reports[0].get("specialty") == "Cardiology";

    # 5. Staff Login: Nurse, Pharmacist, Admin
    nurse_login = root spawn AuthStaff(staff_id="NURSE-001", password="nurse123", hospital_id="hosp-nhsl-01", role="nurse");
    assert nurse_login.reports[0].get("ok") == True;
    assert nurse_login.reports[0].get("role") == "nurse";

    admin_login = root spawn AuthStaff(staff_id="ADMIN-001", password="admin123", hospital_id="hosp-nhsl-01", role="admin");
    assert admin_login.reports[0].get("ok") == True;
    assert admin_login.reports[0].get("role") == "admin";
}

test "7. Healthcare Facilities Catalog (MRI, CT, Endoscopy, Prep Instructions)" {
    fac_res = root spawn GetHospitalFacilities(hospital_id="hosp-nhsl-01");
    assert len(fac_res.reports) > 0;
    facilities = fac_res.reports[0].get("facilities", []);
    assert len(facilities) == 13;

    # Check MRI exists with full instructions
    mri_found = False;
    for f in facilities {
        if f.get("key") == "mri" {
            mri_found = True;
            assert "Magnetic Resonance" in f.get("name", "");
            prep = f.get("prep_instructions", []);
            assert len(prep) >= 3;
            break;
        }
    }
    assert mri_found == True;

    # Nurse updates facility status in real time
    update_res = root spawn ManageFacility(
        hospital_id="hosp-nhsl-01",
        facility_key="mri",
        status="busy",
        current_wait_minutes=90,
        actor="Sister Bandara"
    );
    assert update_res.reports[0].get("ok") == True;
    assert update_res.reports[0].get("status") == "busy";
}

test "8. Patient Health Records, Vitals Logging & Allergy Guard" {
    # 1. Fetch Patient Health Record
    health_res = root spawn GetPatientHealth(patient_id="pat-4567-34", actor_role="patient");
    assert health_res.reports[0].get("ok") == True;
    pat_data = health_res.reports[0];
    assert len(pat_data.get("conditions", [])) >= 1;
    assert len(pat_data.get("allergies", [])) >= 1;
    assert "Penicillin" in pat_data.get("allergies", [])[0];

    # 2. Patient logs a reading
    vital_res = root spawn LogPatientVitals(
        patient_id="pat-4567-34",
        actor="Kasun Bandara",
        bp="124/80 mmHg",
        glucose="95 mg/dL"
    );
    assert vital_res.reports[0].get("ok") == True;
    assert vital_res.reports[0].get("vitals", {}).get("bp") == "124/80 mmHg";

    # 3. Doctor prescribes item with allergy conflict (Penicillin / Amoxicillin)
    conflict_rx = root spawn DoctorPrescribeWithAllergyCheck(
        patient_id="pat-4567-34",
        patient_name="Kasun Bandara",
        doctor_id="doc-nhsl-02",
        doctor_name="Dr. Priyantha Senaratne",
        items="Amoxicillin 500mg tds",
        confirmed_override=False
    );
    assert conflict_rx.reports[0].get("ok") == False;
    assert conflict_rx.reports[0].get("allergy_warning") == True;

    # 4. Doctor overrides warning with confirmation
    confirm_rx = root spawn DoctorPrescribeWithAllergyCheck(
        patient_id="pat-4567-34",
        patient_name="Kasun Bandara",
        doctor_id="doc-nhsl-02",
        doctor_name="Dr. Priyantha Senaratne",
        items="Amoxicillin 500mg tds",
        confirmed_override=True
    );
    assert confirm_rx.reports[0].get("ok") == True;
    assert confirm_rx.reports[0].get("status") == "sent";

    # 5. Doctor overrides AI triage suggestion
    triage_ov = root spawn DoctorTriageAction(
        doctor_id="doc-nhsl-02",
        doctor_name="Dr. Priyantha Senaratne",
        patient_id="pat-4567-34",
        action="override",
        new_specialty="Cardiothoracic Surgery",
        new_priority="Urgent",
        reason="Clinical review indicates murmurs with exercise intolerance."
    );
    assert triage_ov.reports[0].get("ok") == True;
    assert triage_ov.reports[0].get("action") == "override";

    # Check AI Overrides log
    ov_logs = root spawn GetAIOverrides();
    assert len(ov_logs.reports[0].get("overrides", [])) >= 1;
}

test "9. Doctor Profile Security (Internal credentials stripped from public view)" {
    doc_prof = root spawn GetDoctorPublicProfile(doctor_id="doc-nhsl-02");
    assert doc_prof.reports[0].get("ok") == True;
    d = doc_prof.reports[0];
    assert d.get("name") == "Dr. Priyantha Senaratne";
    assert d.get("specialty_name") == "Cardiology";
    # Assert internal private fields are NEVER exposed
    assert "slmc_reg" not in d;
    assert "staff_id" not in d;
    assert "work_email" not in d;
    assert "work_phone" not in d;
}

test "10. Comprehensive Facility Preparation Protocols (MRI, CT, Endoscopy, Dialysis)" {
    mri_proto = get_facility_detailed_protocol("fac-mri-01");
    assert "MRI" in mri_proto.name;
    assert len(mri_proto.contraindications) >= 3;
    assert mri_proto.estimated_duration_mins >= 30;

    ct_proto = get_facility_detailed_protocol("fac-ct-01");
    assert "CT" in ct_proto.name;
    assert "Metformin" in ct_proto.nursing_notes;

    endo_proto = get_facility_detailed_protocol("fac-endo-01");
    assert "Endoscopy" in endo_proto.name;
    assert len(endo_proto.prep_steps) >= 3;
    assert len(endo_proto.contraindications) >= 2;

    dial_proto = get_facility_detailed_protocol("fac-dial-01");
    assert dial_proto.estimated_duration_mins >= 180;
}

test "11. Sri Lanka Ministry of Health Dengue Triage Guidelines" {
    # Test routine monitoring phase
    res_routine = evaluate_dengue_guidelines(
        day_of_fever=2,
        warning_signs=[],
        platelet_count=180000,
        pcv_percent=38.0
    );
    assert res_routine.get("admission_required") == False;
    assert res_routine.get("triage_decision") == "OPD Monitoring";

    # Test critical phase with warning sign
    res_warning = evaluate_dengue_guidelines(
        day_of_fever=4,
        warning_signs=["persistent vomiting", "severe abdominal pain"],
        platelet_count=90000,
        pcv_percent=46.0
    );
    assert res_warning.get("admission_required") == True;
    assert res_warning.get("triage_decision") == "Immediate Ward Admission";

    # Test Dengue Shock Syndrome (DSS)
    res_shock = evaluate_dengue_guidelines(
        day_of_fever=5,
        warning_signs=["shock", "cold clammy extremities"],
        platelet_count=45000,
        pcv_percent=52.0
    );
    assert "ETU" in res_shock.get("triage_decision");
    assert res_shock.get("iv_fluid_needed") == True;
}

test "12. Clinical Risk Calculators (CURB-65, Wells DVT, GCS)" {
    # CURB-65
    curb_low = calculate_curb65(
        confusion=False,
        bun_gt_7=False,
        rr_gte_30=False,
        sbp_lt_90_or_dbp_lte_60=False,
        age_gte_65=False
    );
    assert curb_low.score == 0;
    assert "Low Risk" in curb_low.risk_level;

    curb_high = calculate_curb65(
        confusion=True,
        bun_gt_7=True,
        rr_gte_30=True,
        sbp_lt_90_or_dbp_lte_60=True,
        age_gte_65=True
    );
    assert curb_high.score == 5;
    assert "High Risk" in curb_high.risk_level;

    # Wells DVT Score
    wells_dvt = calculate_wells_dvt([
        "active_cancer",
        "calf_swelling_gt_3cm",
        "pitting_edema"
    ]);
    assert wells_dvt.score == 3;
    assert "Likely" in wells_dvt.risk_level;

    # Glasgow Coma Scale (GCS)
    gcs_normal = calculate_glasgow_coma_scale(eye=4, verbal=5, motor=6);
    assert gcs_normal.score == 15;
    assert "Mild" in gcs_normal.risk_level;

    gcs_severe = calculate_glasgow_coma_scale(eye=2, verbal=2, motor=3);
    assert gcs_severe.score == 7;
    assert "Severe" in gcs_severe.risk_level;
}

test "13. National Essential Medicines List (NLEM) Drug Interactions & Cross-Allergy" {
    # Drug interaction check: Warfarin + NSAID
    interactions = check_nlem_drug_interactions([
        "Warfarin Sodium 5mg",
        "Diclofenac Sodium 50mg"
    ]);
    assert len(interactions) >= 1;
    assert interactions[0].get("severity") == "CRITICAL";

    # Cross allergy check: Penicillin -> Amoxicillin
    cross_pen = check_allergy_cross_sensitivity(
        prescribed_drug="Amoxicillin 500mg",
        known_allergies=["Penicillin"]
    );
    assert len(cross_pen) >= 1;
    assert cross_pen[0].get("severity") == "CRITICAL";

    # Renal adjustment check: Metformin with low eGFR
    renal_check = check_renal_adjustment_needed("Metformin 500mg", 22.0);
    assert renal_check.get("requires_adjustment") == True;
    assert "CONTRAINDICATED" in renal_check.get("guideline");
}

test "14. Pediatric Dosing Formula Engine" {
    # Paracetamol: 15 mg/kg per dose
    pedia_para = calculate_pediatric_dose("Paracetamol Syrup", 12.0, 36);
    assert pedia_para.single_dose_mg == 180.0;
    assert pedia_para.max_daily_dose_mg == 720.0;

    # Amoxicillin pediatric calculation
    pedia_amox = calculate_pediatric_dose("Amoxicillin Suspension", 15.0, 48);
    assert pedia_amox.single_dose_mg == 150.0;
}

test "15. Maternal & Obstetric Triage Decision Engine" {
    # Routine antenatal check
    mat_routine = evaluate_maternal_triage(
        gestational_weeks=24,
        sbp=110, dbp=70,
        proteinuria=False,
        severe_headache_or_visual=False,
        pv_bleeding=False,
        reduced_fetal_movement=False
    );
    assert mat_routine.get("triage_level") == "Routine Antenatal Clinic";
    assert mat_routine.get("is_emergency") == False;

    # Severe Preeclampsia (SBP >= 160)
    mat_pe = evaluate_maternal_triage(
        gestational_weeks=34,
        sbp=168, dbp=105,
        proteinuria=True,
        severe_headache_or_visual=True,
        pv_bleeding=False,
        reduced_fetal_movement=False
    );
    assert mat_pe.get("is_emergency") == True;
    assert "Preeclampsia" in mat_pe.get("triage_level") or "Eclampsia" in mat_pe.get("triage_level");

    # PV bleeding emergency
    mat_bleed = evaluate_maternal_triage(
        gestational_weeks=32,
        sbp=120, dbp=80,
        proteinuria=False,
        severe_headache_or_visual=False,
        pv_bleeding=True,
        reduced_fetal_movement=False
    );
    assert mat_bleed.get("is_emergency") == True;
    assert "Red" in mat_bleed.get("triage_level");

    # Reduced fetal movement at 30 weeks
    mat_rfm = evaluate_maternal_triage(
        gestational_weeks=30,
        sbp=115, dbp=72,
        proteinuria=False,
        severe_headache_or_visual=False,
        pv_bleeding=False,
        reduced_fetal_movement=True
    );
    assert "Fetal" in mat_rfm.get("triage_level");
}

test "16. Sri Lanka Snakebite Envenomation Protocol" {
    # Dry bite / non-venomous observation
    dry_bite = evaluate_snakebite_protocol(
        bite_marks=True,
        local_swelling_beyond_joint=False,
        incoagulable_blood_20wbct=False,
        ptosis_or_neuro=False,
        oliguria_or_dark_urine=False
    );
    assert dry_bite.get("antivenom_indicated") == False;
    assert dry_bite.get("triage_priority") == "OPD Observation";

    # Hemotoxic envenomation (Russell's Viper)
    hemotoxic = evaluate_snakebite_protocol(
        bite_marks=True,
        local_swelling_beyond_joint=True,
        incoagulable_blood_20wbct=True,
        ptosis_or_neuro=False,
        oliguria_or_dark_urine=False
    );
    assert hemotoxic.get("antivenom_indicated") == True;
    assert "Hemotoxic" in hemotoxic.get("syndrome");

    # Neurotoxic envenomation (Krait / Cobra)
    neurotoxic = evaluate_snakebite_protocol(
        bite_marks=True,
        local_swelling_beyond_joint=False,
        incoagulable_blood_20wbct=False,
        ptosis_or_neuro=True,
        oliguria_or_dark_urine=False
    );
    assert neurotoxic.get("antivenom_indicated") == True;
    assert "Neurotoxic" in neurotoxic.get("syndrome");

    # Severe local envenomation (Hump-nosed Pit Viper)
    local_env = evaluate_snakebite_protocol(
        bite_marks=True,
        local_swelling_beyond_joint=True,
        incoagulable_blood_20wbct=False,
        ptosis_or_neuro=False,
        oliguria_or_dark_urine=False
    );
    assert local_env.get("antivenom_indicated") == False;
    assert "Yellow" in local_env.get("triage_priority");
}

test "17. Acute Asthma Exacerbation Severity Grading" {
    # Mild to moderate
    mild_asthma = evaluate_asthma_severity(
        pefr_percent=65.0,
        can_complete_sentences=True,
        pulse_rate=95,
        respiratory_rate=22,
        spo2_percent=96.0
    );
    assert mild_asthma.get("severity") == "Mild to Moderate Asthma";
    assert mild_asthma.get("transfer_icu") == False;

    # Severe acute asthma
    severe_asthma = evaluate_asthma_severity(
        pefr_percent=30.0,
        can_complete_sentences=False,
        pulse_rate=135,
        respiratory_rate=34,
        spo2_percent=91.0
    );
    assert "Severe" in severe_asthma.get("severity") or "Life-Threatening" in severe_asthma.get("severity");

    # Life-threatening / silent chest
    critical_asthma = evaluate_asthma_severity(
        pefr_percent=25.0,
        can_complete_sentences=False,
        pulse_rate=140,
        respiratory_rate=38,
        spo2_percent=88.0
    );
    assert "Life-Threatening" in critical_asthma.get("severity");
    assert critical_asthma.get("transfer_icu") == True;
}

test "18. Trilingual (Sinhala, Tamil, English) System Localization" {
    # 1. Sinhala localization check
    si_strings = get_trilingual_strings("si");
    assert si_strings.get("lang") == "si";
    assert "ස්මාර්ට්" in si_strings.get("brand_title");
    assert "රෝහල්" in si_strings.get("nav_directory");

    # 2. Tamil localization check
    ta_strings = get_trilingual_strings("ta");
    assert ta_strings.get("lang") == "ta";
    assert "ஸ்மார்ட்" in ta_strings.get("brand_title");
    assert "மருத்துவமனை" in ta_strings.get("nav_directory");

    # 3. English localization check
    en_strings = get_trilingual_strings("en");
    assert en_strings.get("lang") == "en";
    assert "Smart Hospital OPD" == en_strings.get("brand_title");
    assert "Public Directory" in en_strings.get("nav_directory");

    # 4. Walker invocation check
    res = root spawn GetI18nStrings(lang="si");
    assert len(res.reports) > 0;
    assert res.reports[0].get("lang") == "si";
    assert res.strings.get("lang") == "si";
    assert "රෝහල්" in res.strings.get("nav_directory");
}

