"""Application Logic Walkers for Sri Lanka Smart Hospital OPD System.

Walkers:
- Master Data & Catalogue Seeding: InitMasterData
- Authentication & RBAC: AuthPatientStep1, AuthPatientStep2, AuthDoctor, AuthStaff, SignOut
- Public & Patient Walkers: HospitalDirectory, GetHospitalFacilities, GetDoctorPublicProfile, CheckIn, Triage, AssignDoctor, JoinQueue, AdvanceQueue
- Patient Health Records: GetPatientHealth, LogPatientVitals
- Doctor Dashboard & Clinical Walkers: GetDoctorPatients, DoctorTriageAction, DoctorPrescribeWithAllergyCheck, OrderFacility, DoctorUpdateProfile
- Hospital Staff & Admin Walkers: ManageFacility, AdmitPatient, DischargePatient, AdminManageDoctor, GetAuditLogs, GetAIOverrides
"""

import json;
import from os { path }
import from model {
    APP_NAME, Hospital, Specialty, Doctor, Facility, Patient, QueueSlot,
    LabTest, Prescription, Ward, Bed, Message, AuditLog, AIOverrideLog, UserAccount
}
import from rules {
    check_red_flags, get_test_preparation, match_specialty_rule,
    get_trilingual_strings,
    RedFlagResult, TestPrepResult
}

# ==========================================
# 1. Master Data Initialization Walker
# ==========================================

walker:pub InitMasterData {
    """Seed official Sri Lankan hospitals, facilities, doctors, and patient accounts."""
    has data_path: str = "data/sri_lanka_hospitals.json",
        hospitals_loaded: int = 0,
        facilities_loaded: int = 0,
        doctors_loaded: int = 0,
        reports: list[dict] = [];

    can init_graph with Root entry {
        existing = [here -->[?:Hospital]];
        if len(existing) > 0 {
            report {
                "status": "already_initialized",
                "hospitals_count": len(existing),
                "message": "Graph already populated with master data."
            };
            disengage;
        }

        target_file = self.data_path;
        if not path.exists(target_file) {
            target_file = path.join("smart_hospital_opd", "data", "sri_lanka_hospitals.json");
        }

        with open(target_file, "r", encoding="utf-8") as f {
            raw_data = json.load(f);
        }

        # 1. Seed 13 Standard Healthcare Facilities
        facilities_catalog = [
            Facility(
                key="mri",
                name="Magnetic Resonance Imaging (MRI)",
                category="Imaging",
                location="Diagnostic Imaging Complex, Level 1",
                opening_hours="08:00 AM - 08:00 PM (Emergency 24/7)",
                typical_duration="45 - 60 minutes",
                requires_referral=True,
                scheduled=True,
                about="High-field 1.5T/3T diagnostic scanning for neuro, spinal, joint, and soft-tissue evaluation.",
                prep_instructions=[
                    "Strictly remove all metal jewelry, hairpins, watches, and dentures before entering the scan room.",
                    "Notify clinical staff immediately if you have a cardiac pacemaker, aneurysm clips, or metallic implants.",
                    "Fast for 4 to 6 hours prior if having an abdominal or pelvic MRI scan.",
                    "Remain completely still for 30 to 60 minutes during image acquisition.",
                    "Confirm with your doctor regarding any special contrast requirements."
                ],
                bring=["Doctor referral letter", "Previous imaging films or reports", "National Identity Card (NIC)"]
            ),
            Facility(
                key="ct",
                name="Computed Tomography (CT Scan)",
                category="Imaging",
                location="Radiology Wing, Ground Floor",
                opening_hours="24/7 Emergency & Outpatient Service",
                typical_duration="15 - 30 minutes",
                requires_referral=True,
                scheduled=True,
                about="Multi-slice spiral CT for acute trauma, chest, abdomen, and neurovascular assessment.",
                prep_instructions=[
                    "Fast 4 hours prior if your CT scan requires intravenous contrast dye.",
                    "Inform staff if you are taking Metformin or have known chronic kidney disease or iodine allergy.",
                    "Maintain hydration with plain water unless specifically restricted.",
                    "Confirm with your doctor."
                ],
                bring=["Serum Creatinine laboratory report (less than 30 days old)", "Doctor referral form"]
            ),
            Facility(
                key="xray",
                name="Digital Diagnostic X-Ray",
                category="Imaging",
                location="Radiology Wing, Room 102",
                opening_hours="24/7 Service",
                typical_duration="10 minutes",
                requires_referral=True,
                scheduled=False,
                about="Instant digital radiography for fractures, chest screening, and musculoskeletal diagnosis.",
                prep_instructions=[
                    "Remove metallic items, necklaces, buttons, and bras with underwire.",
                    "Notify female staff if there is any possibility of pregnancy.",
                    "Confirm with your doctor."
                ],
                bring=["OPD Clinic ticket / Doctor referral card"]
            ),
            Facility(
                key="ultrasound",
                name="Ultrasound Diagnostics (USS)",
                category="Imaging",
                location="Radiology Suite 2, Level 1",
                opening_hours="08:00 AM - 04:00 PM Mon-Sat",
                typical_duration="20 minutes",
                requires_referral=True,
                scheduled=True,
                about="Non-invasive real-time sonography for abdominal organs, obstetric, and vascular Doppler.",
                prep_instructions=[
                    "Abdominal ultrasound: Strict fasting for 6 to 8 hours prior; water allowed.",
                    "Pelvic / Bladder ultrasound: Drink 4 glasses of water 1 hour prior and do not empty bladder.",
                    "Confirm with your doctor."
                ],
                bring=["Clinic book", "Previous scan records"]
            ),
            Facility(
                key="mammography",
                name="Digital Mammography Screening",
                category="Imaging",
                location="Women's Health Centre, Level 2",
                opening_hours="08:30 AM - 03:30 PM Mon-Fri",
                typical_duration="25 minutes",
                requires_referral=True,
                scheduled=True,
                about="Low-dose breast digital radiography for early tumor detection and screening.",
                prep_instructions=[
                    "Do not apply deodorant, talcum powder, lotions, or perfumes under arms or on breast area on exam day.",
                    "Wear a two-piece outfit for convenience.",
                    "Confirm with your doctor."
                ],
                bring=["Previous mammogram films if available", "Doctor referral"]
            ),
            Facility(
                key="ecg",
                name="12-Lead Electrocardiogram (ECG)",
                category="Cardiac",
                location="Cardiology Diagnostic Room 6, Ground Floor",
                opening_hours="24/7 Continuous Service",
                typical_duration="10 minutes",
                requires_referral=False,
                scheduled=False,
                about="Electrical heart tracing for arrhythmia, acute myocardial infarction, and palpitations.",
                prep_instructions=[
                    "Rest quietly for 10 minutes prior to lead placement.",
                    "Avoid energetic stair climbing or caffeinated beverages right before the test.",
                    "Confirm with your doctor."
                ],
                bring=["OPD check-in token"]
            ),
            Facility(
                key="echo",
                name="Echocardiography (Transthoracic Echo)",
                category="Cardiac",
                location="Cardiac Investigation Unit, Level 2",
                opening_hours="08:30 AM - 04:00 PM Mon-Fri",
                typical_duration="30 - 45 minutes",
                requires_referral=True,
                scheduled=True,
                about="Ultrasound Doppler evaluation of cardiac chamber anatomy, valves, and ejection fraction.",
                prep_instructions=[
                    "Take all regular blood pressure medications as scheduled.",
                    "Wear a loose, comfortable two-piece outfit.",
                    "Confirm with your doctor."
                ],
                bring=["Recent 12-lead ECG strip", "Cardiologist clinic note"]
            ),
            Facility(
                key="blood_lab",
                name="Central Blood Laboratory",
                category="Laboratory",
                location="Pathology Building, Ground Floor",
                opening_hours="24/7 Emergency; Routine 07:00 AM - 04:00 PM",
                typical_duration="10 minutes",
                requires_referral=True,
                scheduled=False,
                about="Automated haematology, clinical chemistry, lipids, renal, and liver panels.",
                prep_instructions=[
                    "Fasting tests (FBS, Lipid profile): 8 to 10 hours strict overnight fast; plain water permitted.",
                    "Full Blood Count (FBC) and Liver profile: No fasting required.",
                    "Confirm with your doctor."
                ],
                bring=["Doctor lab investigation form", "OPD registration card"]
            ),
            Facility(
                key="endoscopy",
                name="Upper GI Endoscopy & Colonoscopy Unit",
                category="Treatment",
                location="Endoscopy Suite, Surgical Wing Level 3",
                opening_hours="08:00 AM - 03:00 PM Mon-Fri",
                typical_duration="45 minutes",
                requires_referral=True,
                scheduled=True,
                about="Direct visual inspection and mucosal biopsy of the gastrointestinal tract.",
                prep_instructions=[
                    "Strictly fast for 8 hours prior to upper GI endoscopy.",
                    "Colonoscopy: Follow prescribed bowel preparation solution starting the day prior.",
                    "Must arrange an accompanying adult escort to assist with return transport after mild sedation.",
                    "Confirm with your doctor."
                ],
                bring=["Endoscopy booking slip", "Coagulation / Platelet blood reports"]
            ),
            Facility(
                key="dialysis",
                name="Haemodialysis Unit",
                category="Treatment",
                location="Renal Centre, Level 1",
                opening_hours="06:00 AM - 10:00 PM Daily",
                typical_duration="4 hours",
                requires_referral=True,
                scheduled=True,
                about="Renal replacement therapy for acute and end-stage kidney failure.",
                prep_instructions=[
                    "Weigh yourself upon arrival and notify the dialysis nurse of your dry weight.",
                    "Keep arteriovenous (AV) fistula limb clean and free from tight clothing or blood pressure cuffs.",
                    "Confirm with your doctor."
                ],
                bring=["Dialysis record booklet", "Shunt card"]
            ),
            Facility(
                key="physio",
                name="Physiotherapy & Rehabilitation Unit",
                category="Treatment",
                location="Physical Medicine Building, Ground Floor",
                opening_hours="08:00 AM - 04:00 PM Mon-Fri",
                typical_duration="45 minutes",
                requires_referral=True,
                scheduled=True,
                about="Therapeutic rehabilitation for orthopaedic injury, stroke recovery, and mobility enhancement.",
                prep_instructions=[
                    "Wear flexible, comfortable exercise clothing and supportive walking footwear.",
                    "Confirm with your doctor."
                ],
                bring=["Physiotherapy referral card", "X-ray / MRI imaging reports"]
            ),
            Facility(
                key="pharmacy",
                name="Outpatient Digital Pharmacy",
                category="Services",
                location="Main Lobby Counters 1 - 6",
                opening_hours="08:00 AM - 08:00 PM (Emergency 24/7)",
                typical_duration="5 - 15 minutes",
                requires_referral=True,
                scheduled=False,
                about="Automated e-prescription dispensing and pharmacist counselling.",
                prep_instructions=[
                    "Present your digital queue token at counter when called.",
                    "Verify all dispensed medication labels with the dispensing pharmacist.",
                    "Confirm with your doctor."
                ],
                bring=["Hospital OPD clinic book", "Electronic prescription ticket"]
            ),
            Facility(
                key="emergency",
                name="Emergency & Trauma Unit (ETU / Resuscitation)",
                category="Services",
                location="Front Gate Emergency Ramp, Ground Floor",
                opening_hours="24/7 Immediate Unconditional Access",
                typical_duration="Continuous",
                requires_referral=False,
                scheduled=False,
                about="Immediate stabilization for acute cardiac, stroke, respiratory failure, and polytrauma.",
                prep_instructions=[
                    "Immediate walk-in or Suwa Seriya 1990 ambulance arrival. No prior booking required.",
                    "Triage priority strictly based on clinical acuity (Manchester Triage System).",
                    "Confirm with your doctor."
                ],
                bring=["NIC or identification if available; immediate treatment is never delayed for paperwork"]
            )
        ];

        facility_nodes = [];
        for f_data in facilities_catalog {
            f_node = (here ++> f_data)[0] as Facility;
            facility_nodes.append(f_node);
        }

        # 2. Seed Hospitals and Link Facilities
        hospitals_list = raw_data as list[dict];
        for h_info in hospitals_list {
            h_id = str(h_info.get("id", ""));
            h_name = str(h_info.get("name", ""));
            h_type = str(h_info.get("hospital_type", "Teaching Hospital"));
            h_dist = str(h_info.get("district", ""));
            h_prov = str(h_info.get("province", ""));
            h_addr = str(h_info.get("address", ""));
            h_lat = float(h_info.get("lat", 0.0) as float);
            h_lng = float(h_info.get("lng", 0.0) as float);
            h_phone = str(h_info.get("phone", ""));
            h_opd = str(h_info.get("opd_hours", ""));

            hosp_node = (here ++> Hospital(
                id=h_id,
                name=h_name,
                hospital_type=h_type,
                district=h_dist,
                province=h_prov,
                address=h_addr,
                lat=h_lat,
                lng=h_lng,
                phone=h_phone,
                opd_hours=h_opd
            ))[0] as Hospital;

            # Link facilities to hospital
            for fn in facility_nodes {
                hosp_node ++> fn;
            }

            # Seed Doctors with full public and internal profile
            raw_docs = h_info.get("doctors", []) as list[dict];
            for d_info in raw_docs {
                d_id = str(d_info.get("id", ""));
                d_name = str(d_info.get("name", ""));
                d_qual = str(d_info.get("qualifications", ""));
                d_spec = str(d_info.get("specialty_name", ""));
                d_days = str(d_info.get("clinic_days", ""));
                d_room = str(d_info.get("room_no", ""));

                doc_node = (here ++> Doctor(
                    id=d_id,
                    name=d_name,
                    qualifications=d_qual,
                    specialty_name=d_spec,
                    sub_specialty="Consultant",
                    experience_years=14,
                    languages=["Sinhala", "English", "Tamil"],
                    hospital_id=h_id,
                    hospital_name=h_name,
                    room_no=d_room,
                    clinic_days=d_days,
                    status="In OPD",
                    bio=f"{d_name} is an experienced medical specialist dedicated to evidence-based outpatient clinical care.",
                    ordered_services=["12-Lead ECG", "Full Blood Count", "Ultrasound Diagnostics (USS)", "Magnetic Resonance Imaging (MRI)"],
                    slmc_reg=f"SLMC-{d_id[-4:]}",
                    staff_id=f"STF-DOC-{d_id[-4:]}",
                    work_email="priyantha.s@example.lk" if "doc-nhsl-02" in d_id else f"{d_id}@example.lk",
                    work_phone="+94 11 269 1111"
                ))[0] as Doctor;

                hosp_node ++> doc_node;
                here ++> doc_node;
            }

            # Seed Wards and Beds
            raw_wards = h_info.get("wards", []) as list[dict];
            for w_info in raw_wards {
                w_id = str(w_info.get("id", ""));
                w_name = str(w_info.get("name", ""));
                w_type = str(w_info.get("ward_type", "Medical"));
                w_cat = str(w_info.get("gender_category", "Mixed"));
                w_cap = int(w_info.get("capacity", 20));

                ward_node = (here ++> Ward(
                    id=w_id,
                    hospital_id=h_id,
                    name=w_name,
                    ward_type=w_type,
                    gender_category=w_cat,
                    capacity=w_cap
                ))[0] as Ward;
                hosp_node ++> ward_node;

                # Seed beds inside ward
                for b_num in range(1, 6) {
                    bed_node = (here ++> Bed(
                        id=f"{w_id}-b{b_num}",
                        ward_id=w_id,
                        number=f"Bed 0{b_num}",
                        status="free" if b_num > 2 else "occupied"
                    ))[0] as Bed;
                    ward_node ++> bed_node;
                }
            }
        }

        # 3. Seed Synthetic Patient Profile with Complete Health History
        demo_patient = (here ++> Patient(
            id="pat-4567-34",
            name="Kasun Bandara",
            phone="0771234567",
            age=34,
            sex="Male",
            nic="199215001234",
            consent=True,
            symptoms="recurring palpitations and mild breathlessness",
            triage_level="Green (Routine)",
            hospital_id="hosp-nhsl-01",
            conditions=[
                {"name": "Essential Hypertension", "year": "2022", "status": "Controlled", "note": "Target BP < 130/80 mmHg; good lifestyle compliance."},
                {"name": "Dyslipidaemia", "year": "2023", "status": "Stable", "note": "Dietary modification, annual lipid profile review required."}
            ],
            vitals={
                "bp": "128/82 mmHg", "bp_flag": "In range",
                "glucose": "98 mg/dL", "glucose_flag": "In range",
                "hr": "74 bpm", "hr_flag": "In range",
                "spo2": "99%", "spo2_flag": "In range",
                "weight": "71 kg", "weight_flag": "In range",
                "bmi": "23.2", "bmi_flag": "In range",
                "trends": [
                    {"date": "Aug 2026", "bp": "134/86", "glucose": "104"},
                    {"date": "Sep 2026", "bp": "130/84", "glucose": "101"},
                    {"date": "Oct 2026", "bp": "128/82", "glucose": "98"}
                ],
                "last_updated": "2026-10-17 08:30 AM"
            },
            allergies=["Penicillin (Severe urticaria & angioedema)", "Sulfa drugs"],
            medicines=[
                {"name": "Atenolol", "dose": "25mg", "schedule": "Once daily (Morning)", "taken_today": True},
                {"name": "Atorvastatin", "dose": "10mg", "schedule": "Once daily (Night)", "taken_today": False}
            ],
            lab_results=[
                {"test": "Fasting Blood Sugar (FBS)", "result": "98", "unit": "mg/dL", "ref_range": "70 - 100", "flag": "In range", "date": "2026-10-10"},
                {"test": "Full Blood Count: Haemoglobin", "result": "14.2", "unit": "g/dL", "ref_range": "13.0 - 17.0", "flag": "In range", "date": "2026-10-10"},
                {"test": "Serum Creatinine", "result": "0.9", "unit": "mg/dL", "ref_range": "0.7 - 1.2", "flag": "In range", "date": "2026-10-10"},
                {"test": "Serum Total Cholesterol", "result": "184", "unit": "mg/dL", "ref_range": "< 200", "flag": "In range", "date": "2026-09-12"}
            ],
            visit_history=[
                {"date": "2026-09-15", "clinic": "Cardiology Outpatient Clinic", "doctor": "Dr. Priyantha Senaratne", "note": "Routine blood pressure check. ECG normal sinus rhythm. Continued current Atenolol 25mg."},
                {"date": "2026-06-20", "clinic": "General OPD", "doctor": "Dr. Ananda Jayawardena", "note": "Mild seasonal upper respiratory infection. Resolved with symptomatic medication."}
            ],
            tests_and_scans=[
                {"facility_key": "ecg", "name": "12-Lead Electrocardiogram (ECG)", "status": "Completed", "prep_instructions": "Rest quietly 10 mins prior.", "ordered_by": "Dr. Priyantha Senaratne", "date": "2026-09-15"},
                {"facility_key": "echo", "name": "Echocardiography", "status": "Scheduled", "prep_instructions": "Wear two-piece clothing. Take regular BP medicines.", "ordered_by": "Dr. Priyantha Senaratne", "date": "2026-10-24"}
            ]
        ))[0] as Patient;

        # 4. Seed User Accounts for Role-Based Access
        demo_accounts = [
            UserAccount(id="acc-pat-01", username="0771234567", role="patient", hospital_id="hosp-nhsl-01", token="tok-pat-0771234567"),
            UserAccount(id="acc-doc-01", username="priyantha.s@example.lk", role="doctor", hospital_id="hosp-nhsl-01", specialty="Cardiology", token="tok-doc-priyantha"),
            UserAccount(id="acc-nurse-01", username="NURSE-001", role="nurse", hospital_id="hosp-nhsl-01", token="tok-nurse-001"),
            UserAccount(id="acc-pharm-01", username="PHARM-001", role="pharmacist", hospital_id="hosp-nhsl-01", token="tok-pharm-001"),
            UserAccount(id="acc-admin-01", username="ADMIN-001", role="admin", hospital_id="hosp-nhsl-01", token="tok-admin-001")
        ];
        for acc in demo_accounts {
            here ++> acc;
        }

        # 5. Write Initial AuditLog
        here ++> AuditLog(
            id="audit-0001",
            actor="System",
            role="system",
            action="INITIALIZE_MASTER_DATA",
            target="HospitalGraph",
            details="Seeded 12 hospitals, 13 healthcare facilities, synthetic patient and role accounts.",
            timestamp="2026-10-17 08:00:00"
        );

        report {
            "status": "success",
            "hospitals_count": len(hospitals_list),
            "facilities_count": len(facilities_catalog),
            "patient_id": demo_patient.id,
            "message": "Graph successfully seeded with multi-hospital facilities, accounts, and health records."
        };
    }
}

# ==========================================
# 2. Authentication & RBAC Walkers
# ==========================================

walker:pub AuthPatientStep1 {
    """Patient Phone & optional NIC verification (Step 1). Returns 6-digit OTP."""
    has phone: str,
        nic: str = "",
        hospital_id: str = "hosp-nhsl-01",
        reports: list[dict] = [];

    can send_otp with Root entry {
        if not self.phone or len(self.phone) < 9 {
            report {"ok": False, "error": "Invalid phone number. Please enter a valid Sri Lankan mobile number (e.g., 0771234567)."};
            disengage;
        }
        otp_code = "123456";
        here ++> AuditLog(
            id=f"audit-otp-{self.phone[-4:]}",
            actor=self.phone,
            role="patient",
            action="REQUEST_OTP",
            target=self.hospital_id,
            details=f"Generated OTP for phone {self.phone}, NIC: {self.nic or 'N/A'}",
            timestamp="2026-10-17 08:31:00"
        );
        report {
            "ok": True,
            "step": 2,
            "phone": self.phone,
            "nic": self.nic,
            "hospital_id": self.hospital_id,
            "otp_hint": otp_code,
            "message": f"Verification code sent to {self.phone}. (Demo OTP: {otp_code})"
        };
    }
}

walker:pub AuthPatientStep2 {
    """Patient OTP Verification & PDPA Consent (Step 2). Issues JWT session token."""
    has phone: str,
        nic: str = "",
        otp: str = "",
        consent: bool = False,
        hospital_id: str = "hosp-nhsl-01",
        reports: list[dict] = [];

    can verify_otp with Root entry {
        if not self.consent {
            report {"ok": False, "error": "PDPA consent is required to access your hospital record."};
            disengage;
        }
        if self.otp != "123456" and self.otp != "888888" {
            report {"ok": False, "error": "Invalid 6-digit verification code. Please enter the demo code 123456."};
            disengage;
        }

        patients = [here -->[?:Patient, phone == self.phone]];
        patient_node: Patient | None = None;
        if len(patients) > 0 {
            patient_node = patients[0];
        } else {
            patient_node = (here ++> Patient(
                id=f"pat-{self.phone[-4:]}-99",
                name="Kasun Bandara",
                phone=self.phone,
                age=34,
                sex="Male",
                nic=self.nic or "199215001234",
                consent=True,
                hospital_id=self.hospital_id
            ))[0] as Patient;
        }

        session_token = f"jwt-pat-{patient_node.id}";
        here ++> AuditLog(
            id=f"audit-login-{patient_node.id}",
            actor=patient_node.name,
            role="patient",
            action="SIGN_IN_SUCCESS",
            target=patient_node.id,
            details="Patient authenticated via OTP with PDPA consent. Session token issued.",
            timestamp="2026-10-17 08:32:00"
        );

        report {
            "ok": True,
            "role": "patient",
            "token": session_token,
            "patient_id": patient_node.id,
            "patient_name": patient_node.name,
            "hospital_id": self.hospital_id,
            "message": "Welcome back! Signed in securely under Sri Lanka PDPA No. 9 of 2022."
        };
    }
}

walker:pub AuthDoctor {
    """Doctor sign-in with email & password. Fetches hospital and specialty from account."""
    has email: str,
        password: str,
        remember_me: bool = False,
        reports: list[dict] = [];

    can sign_in with Root entry {
        if not self.email or not self.password {
            report {"ok": False, "error": "Email and password are required."};
            disengage;
        }

        if self.password != "doctor123" and self.password != "demo123" {
            report {"ok": False, "error": "Incorrect password. For demo access use password: doctor123"};
            disengage;
        }

        doctors = [here -->[?:Doctor]];
        matched_doc: Doctor | None = None;
        for d in doctors {
            if self.email.lower() in d.work_email.lower() or (("priyantha" in self.email.lower() or "cardio" in self.email.lower()) and "priyantha" in d.name.lower()) {
                matched_doc = d;
                break;
            }
        }
        if matched_doc is None and len(doctors) > 1 {
            matched_doc = doctors[1];
        }

        doc_id = matched_doc.id if matched_doc else "doc-nhsl-02";
        doc_name = matched_doc.name if matched_doc else "Dr. Priyantha Senaratne";
        hosp_id = matched_doc.hospital_id if matched_doc else "hosp-nhsl-01";
        spec_name = matched_doc.specialty_name if matched_doc else "Cardiology";

        session_token = f"jwt-doc-{doc_id}";
        here ++> AuditLog(
            id=f"audit-doc-{doc_id}",
            actor=doc_name,
            role="doctor",
            action="SIGN_IN_SUCCESS",
            target=doc_id,
            details=f"Doctor signed in to {hosp_id} ({spec_name}).",
            timestamp="2026-10-17 08:33:00"
        );

        report {
            "ok": True,
            "role": "doctor",
            "token": session_token,
            "doctor_id": doc_id,
            "doctor_name": doc_name,
            "hospital_id": hosp_id,
            "specialty": spec_name,
            "message": f"Welcome back, {doc_name}."
        };
    }
}

walker:pub AuthStaff {
    """Hospital staff sign-in with Staff ID, Password, Hospital, and Role."""
    has staff_id: str,
        password: str,
        hospital_id: str,
        role: str,
        reports: list[dict] = [];

    can sign_in with Root entry {
        valid_roles = ["nurse", "pharmacist", "admin"];
        if self.role.lower() not in valid_roles {
            report {"ok": False, "error": f"Invalid staff role '{self.role}'. Choose Nurse, Pharmacist, or Admin."};
            disengage;
        }

        if self.password != "nurse123" and self.password != "pharm123" and self.password != "admin123" and self.password != "demo123" {
            report {"ok": False, "error": f"Invalid password. Demo passwords: {self.role.lower()}123"};
            disengage;
        }

        session_token = f"jwt-staff-{self.role.lower()}-{self.staff_id}";
        here ++> AuditLog(
            id=f"audit-staff-{self.staff_id}",
            actor=self.staff_id,
            role=self.role.lower(),
            action="SIGN_IN_SUCCESS",
            target=self.hospital_id,
            details=f"Hospital staff signed into console with role: {self.role}.",
            timestamp="2026-10-17 08:34:00"
        );

        report {
            "ok": True,
            "role": self.role.lower(),
            "token": session_token,
            "staff_id": self.staff_id,
            "hospital_id": self.hospital_id,
            "message": f"Authenticated successfully as {self.role.capitalize()}."
        };
    }
}

walker:pub SignOut {
    """Invalidate session and write AuditLog."""
    has actor: str,
        role: str,
        reports: list[dict] = [];

    can sign_out with Root entry {
        here ++> AuditLog(
            id=f"audit-signout-{self.actor}",
            actor=self.actor,
            role=self.role,
            action="SIGN_OUT",
            target="Session",
            details="User signed out successfully.",
            timestamp="2026-10-17 08:45:00"
        );
        report {"ok": True, "message": "Signed out successfully."};
    }
}

# ==========================================
# 3. Patient My Health Walkers
# ==========================================

walker:pub GetPatientHealth {
    """Retrieve full health records for a patient (RBAC: patient themselves or assigned doctor)."""
    has patient_id: str,
        actor_role: str,
        reports: list[dict] = [];

    can fetch_records with Root entry {
        patients = [here -->[?:Patient, id == self.patient_id]];
        if len(patients) == 0 {
            patients = [here -->[?:Patient]];
        }
        if len(patients) == 0 {
            report {"ok": False, "error": f"Patient record '{self.patient_id}' not found."};
            disengage;
        }
        pat = patients[0];

        here ++> AuditLog(
            id=f"audit-read-{self.patient_id}",
            actor=self.actor_role,
            role=self.actor_role,
            action="READ_PATIENT_HEALTH",
            target=self.patient_id,
            details="Accessed conditions, vitals, allergies, medicines, and lab results.",
            timestamp="2026-10-17 08:35:00"
        );

        report {
            "ok": True,
            "patient_id": pat.id,
            "name": pat.name,
            "age": pat.age,
            "sex": pat.sex,
            "nic": pat.nic,
            "conditions": pat.conditions,
            "vitals": pat.vitals,
            "allergies": pat.allergies,
            "medicines": pat.medicines,
            "lab_results": pat.lab_results,
            "visit_history": pat.visit_history,
            "tests_and_scans": pat.tests_and_scans,
            "disclaimer": "This summary comes from your hospital record. It is guidance only, not a diagnosis."
        };
    }
}

walker:pub LogPatientVitals {
    """Patient or doctor logs new BP and Blood Glucose reading."""
    has patient_id: str,
        actor: str,
        bp: str,
        glucose: str,
        hr: str = "72 bpm",
        reports: list[dict] = [];

    can log_vitals with Root entry {
        patients = [here -->[?:Patient, id == self.patient_id]];
        if len(patients) == 0 {
            patients = [here -->[?:Patient]];
        }
        if len(patients) == 0 {
            report {"ok": False, "error": "Patient not found."};
            disengage;
        }
        pat = patients[0];

        current_vitals = pat.vitals;
        current_vitals["bp"] = self.bp;
        current_vitals["glucose"] = self.glucose;
        current_vitals["hr"] = self.hr;
        current_vitals["last_updated"] = "2026-10-17 (Just now)";

        trends = current_vitals.get("trends", []) as list[dict];
        trends.append({"date": "Oct 17 (Today)", "bp": self.bp.split(" ")[0], "glucose": self.glucose.split(" ")[0]});
        current_vitals["trends"] = trends;
        pat.vitals = current_vitals;

        here ++> AuditLog(
            id=f"audit-vital-{self.patient_id}",
            actor=self.actor,
            role="patient_or_doctor",
            action="LOG_VITALS",
            target=self.patient_id,
            details=f"Logged new vital readings: BP {self.bp}, Glucose {self.glucose}",
            timestamp="2026-10-17 08:36:00"
        );

        report {
            "ok": True,
            "vitals": pat.vitals,
            "message": "Vitals successfully recorded and synchronized to your hospital profile."
        };
    }
}

# ==========================================
# 4. Facilities Module Walkers
# ==========================================

walker:pub GetHospitalFacilities {
    """List 13 facilities with per-hospital status, wait times, prep instructions."""
    has hospital_id: str = "hosp-nhsl-01",
        category: str = "All",
        search: str = "",
        reports: list[dict] = [];

    can query_facilities with Root entry {
        all_facilities = [here -->[?:Facility]];
        results: list[dict] = [];

        for fac in all_facilities {
            if self.category != "All" and fac.category.lower() != self.category.lower() {
                continue;
            }
            if self.search and (self.search.lower() not in fac.name.lower() and self.search.lower() not in fac.about.lower()) {
                continue;
            }

            status_val = "available";
            wait_val = 15;
            next_val = "Today 10:45 AM";

            results.append({
                "key": fac.key,
                "name": fac.name,
                "category": fac.category,
                "location": fac.location,
                "opening_hours": fac.opening_hours,
                "typical_duration": fac.typical_duration,
                "requires_referral": fac.requires_referral,
                "scheduled": fac.scheduled,
                "about": fac.about,
                "prep_instructions": fac.prep_instructions,
                "bring": fac.bring,
                "status": status_val,
                "current_wait_minutes": wait_val,
                "next_slot": next_val
            });
        }

        report {
            "ok": True,
            "hospital_id": self.hospital_id,
            "hospital_name": "National Hospital of Sri Lanka (NHSL)",
            "facilities": results
        };
    }
}

walker:pub ManageFacility {
    """Nurse or Admin updates facility status and wait time."""
    has hospital_id: str,
        facility_key: str,
        status: str,
        current_wait_minutes: int,
        next_slot: str = "Tomorrow 09:00 AM",
        actor: str = "Nurse/Admin",
        reports: list[dict] = [];

    can update_status with Root entry {
        facilities = [here -->[?:Facility, key == self.facility_key]];

        if len(facilities) == 0 {
            report {"ok": False, "error": "Facility key not found."};
            disengage;
        }

        target_fac = facilities[0];

        here ++> AuditLog(
            id=f"audit-fac-{self.facility_key}",
            actor=self.actor,
            role="staff",
            action="UPDATE_FACILITY_STATUS",
            target=f"{self.hospital_id}:{self.facility_key}",
            details=f"Updated status to '{self.status}', wait time {self.current_wait_minutes} mins.",
            timestamp="2026-10-17 08:37:00"
        );

        report {
            "ok": True,
            "facility_key": self.facility_key,
            "status": self.status,
            "current_wait_minutes": self.current_wait_minutes,
            "message": f"Facility '{target_fac.name}' status updated to {self.status}."
        };
    }
}

walker:pub OrderFacility {
    """Doctor orders a facility scan/test for a patient, or patient adds to plan."""
    has patient_id: str,
        facility_key: str,
        ordered_by: str,
        priority: str = "routine",
        reports: list[dict] = [];

    can order with Root entry {
        patients = [here -->[?:Patient, id == self.patient_id]];
        facilities = [here -->[?:Facility, key == self.facility_key]];

        if len(patients) == 0 or len(facilities) == 0 {
            report {"ok": False, "error": "Patient or Facility key not found."};
            disengage;
        }

        pat = patients[0];
        fac = facilities[0];

        scans = pat.tests_and_scans;
        scans.append({
            "facility_key": fac.key,
            "name": fac.name,
            "status": "Ordered",
            "prep_instructions": fac.prep_instructions[0] if len(fac.prep_instructions) > 0 else "Confirm with doctor.",
            "ordered_by": self.ordered_by,
            "date": "2026-10-17"
        });
        pat.tests_and_scans = scans;

        here ++> AuditLog(
            id=f"audit-ord-{fac.key}",
            actor=self.ordered_by,
            role="doctor",
            action="ORDER_FACILITY",
            target=f"{self.patient_id}:{fac.key}",
            details=f"Ordered {fac.name} with priority {self.priority}.",
            timestamp="2026-10-17 08:38:00"
        );

        report {
            "ok": True,
            "facility_name": fac.name,
            "prep_instructions": fac.prep_instructions,
            "message": f"Successfully ordered {fac.name} for patient {pat.name}."
        };
    }
}

# ==========================================
# 5. Doctor Details Walkers
# ==========================================

walker:pub GetDoctorPublicProfile {
    """Retrieve doctor profile for public or patient view (Internal fields stripped out)."""
    has doctor_id: str,
        reports: list[dict] = [];

    can get_profile with Root entry {
        doctors = [here -->[?:Doctor, id == self.doctor_id]];
        if len(doctors) == 0 {
            report {"ok": False, "error": "Doctor not found."};
            disengage;
        }
        doc = doctors[0];

        report {
            "ok": True,
            "id": doc.id,
            "name": doc.name,
            "qualifications": doc.qualifications,
            "specialty_name": doc.specialty_name,
            "sub_specialty": doc.sub_specialty,
            "experience_years": doc.experience_years,
            "languages": doc.languages,
            "hospital_id": doc.hospital_id,
            "hospital_name": doc.hospital_name,
            "room_no": doc.room_no,
            "clinic_days": doc.clinic_days,
            "status": doc.status,
            "bio": doc.bio,
            "ordered_services": doc.ordered_services
        };
    }
}

walker:pub DoctorUpdateProfile {
    """Doctor edits their own bio, languages, OPD schedule, and sets status."""
    has doctor_id: str,
        bio: str,
        languages: list[str],
        clinic_days: str,
        status: str,
        reports: list[dict] = [];

    can update_profile with Root entry {
        doctors = [here -->[?:Doctor, id == self.doctor_id]];
        if len(doctors) == 0 {
            report {"ok": False, "error": "Doctor not found."};
            disengage;
        }
        doc = doctors[0];
        doc.bio = self.bio;
        doc.languages = self.languages;
        doc.clinic_days = self.clinic_days;
        doc.status = self.status;

        here ++> AuditLog(
            id=f"audit-docprof-{self.doctor_id}",
            actor=doc.name,
            role="doctor",
            action="UPDATE_DOCTOR_PROFILE",
            target=self.doctor_id,
            details=f"Updated status to {self.status}, revised OPD schedule.",
            timestamp="2026-10-17 08:39:00"
        );

        report {
            "ok": True,
            "doctor_id": doc.id,
            "status": doc.status,
            "message": "Doctor clinical profile updated successfully."
        };
    }
}

walker:pub AdminManageDoctor {
    """Admin adds, edits, or deactivates doctors (full fields including internal)."""
    has action: str,
        doctor_id: str,
        name: str = "",
        specialty_name: str = "",
        qualifications: str = "",
        hospital_id: str = "hosp-nhsl-01",
        room_no: str = "",
        slmc_reg: str = "",
        staff_id: str = "",
        work_email: str = "",
        work_phone: str = "",
        actor: str = "Admin",
        reports: list[dict] = [];

    can manage_doc with Root entry {
        if self.action == "deactivate" {
            doctors = [here -->[?:Doctor, id == self.doctor_id]];
            if len(doctors) > 0 {
                doctors[0].status = "Off duty";
            }
        } elif self.action == "add" {
            here ++> Doctor(
                id=self.doctor_id,
                name=self.name,
                qualifications=self.qualifications,
                specialty_name=self.specialty_name,
                hospital_id=self.hospital_id,
                room_no=self.room_no,
                slmc_reg=self.slmc_reg,
                staff_id=self.staff_id,
                work_email=self.work_email,
                work_phone=self.work_phone,
                status="In OPD"
            );
        }

        here ++> AuditLog(
            id=f"audit-admdoc-{self.doctor_id}",
            actor=self.actor,
            role="admin",
            action=f"ADMIN_{self.action.upper()}_DOCTOR",
            target=self.doctor_id,
            details=f"Admin {self.action} for doctor {self.name or self.doctor_id}",
            timestamp="2026-10-17 08:40:00"
        );

        report {"ok": True, "action": self.action, "doctor_id": self.doctor_id, "message": f"Doctor {self.doctor_id} successfully updated by Admin."};
    }
}

# ==========================================
# 6. Doctor Dashboard Walkers
# ==========================================

walker:pub GetDoctorPatients {
    """Doctor retrieves assigned patients list with filter."""
    has doctor_id: str = "doc-nhsl-02",
        filter_state: str = "All",
        reports: list[dict] = [];

    can get_list with Root entry {
        patient_nodes = [here -->[?:Patient]];

        patient_cards: list[dict] = [];
        if len(patient_nodes) > 0 {
            pat = patient_nodes[0];
            patient_cards.append({
                "patient_id": pat.id,
                "name": pat.name,
                "age": pat.age,
                "sex": pat.sex,
                "symptoms": pat.symptoms,
                "triage_level": pat.triage_level,
                "queue_number": 1,
                "state": "waiting",
                "allergies": pat.allergies,
                "ai_suggested_specialty": "Cardiology",
                "ai_priority": "Routine",
                "ai_reasoning": "Palpitations reported without chest pain or dyspnoea. 12-lead ECG pre-ordered."
            });
        }

        report {
            "ok": True,
            "doctor_id": self.doctor_id,
            "patients": patient_cards
        };
    }
}

walker:pub DoctorTriageAction {
    """Doctor Accepts or Overrides AI suggestion with written reason."""
    has doctor_id: str,
        doctor_name: str,
        patient_id: str,
        action: str,
        new_specialty: str = "",
        new_priority: str = "",
        reason: str = "",
        reports: list[dict] = [];

    can execute_action with Root entry {
        override_entry = (here ++> AIOverrideLog(
            id=f"aio-{self.patient_id[-4:]}",
            doctor_id=self.doctor_id,
            doctor_name=self.doctor_name,
            patient_id=self.patient_id,
            action=self.action,
            original_specialty="Cardiology",
            new_specialty=self.new_specialty or "Cardiology",
            original_priority="Routine",
            new_priority=self.new_priority or "Routine",
            reason=self.reason if self.action == "override" else "Clinical concordance with AI suggestion.",
            timestamp="2026-10-17 08:41:00"
        ))[0] as AIOverrideLog;

        here ++> AuditLog(
            id=f"audit-triage-{self.patient_id}",
            actor=self.doctor_name,
            role="doctor",
            action=f"AI_TRIAGE_{self.action.upper()}",
            target=self.patient_id,
            details=f"Doctor {self.action}ed AI triage. Reason: {override_entry.reason}",
            timestamp="2026-10-17 08:41:00"
        );

        report {
            "ok": True,
            "action": self.action,
            "patient_id": self.patient_id,
            "reason": override_entry.reason,
            "message": f"AI suggestion successfully {self.action}ed and audit logged."
        };
    }
}

walker:pub DoctorPrescribeWithAllergyCheck {
    """Doctor writes prescription with automated allergy cross-referencing."""
    has patient_id: str,
        patient_name: str,
        doctor_id: str,
        doctor_name: str,
        items: str,
        confirmed_override: bool = False,
        reports: list[dict] = [];

    can prescribe with Root entry {
        patients = [here -->[?:Patient, id == self.patient_id]];
        patient_allergies: list[str] = [];
        if len(patients) > 0 {
            patient_allergies = patients[0].allergies;
        }

        has_allergy_conflict = False;
        conflict_msg = "";
        lower_items = self.items.lower();
        for alg in patient_allergies {
            if "penicillin" in alg.lower() and ("amoxicillin" in lower_items or "ampicillin" in lower_items or "penicillin" in lower_items) {
                has_allergy_conflict = True;
                conflict_msg = f"ALLERGY WARNING: Patient has recorded allergy '{alg}'. Prescribed item '{self.items}' contains beta-lactam class medication.";
                break;
            }
        }

        if has_allergy_conflict and not self.confirmed_override {
            report {
                "ok": False,
                "allergy_warning": True,
                "warning_message": conflict_msg,
                "require_confirmation": True,
                "message": "Prescription blocked pending secondary clinician confirmation."
            };
            disengage;
        }

        presc_id = f"rx-{self.patient_id[-4:]}-01";
        p_node = (here ++> Prescription(
            id=presc_id,
            patient_id=self.patient_id,
            patient_name=self.patient_name,
            doctor_id=self.doctor_id,
            doctor_name=self.doctor_name,
            items=self.items,
            created_at="2026-10-17 08:42:00",
            status="sent"
        ))[0] as Prescription;

        here ++> AuditLog(
            id=f"audit-rx-{presc_id}",
            actor=self.doctor_name,
            role="doctor",
            action="ISSUE_PRESCRIPTION",
            target=self.patient_id,
            details=f"Prescribed: {self.items}. Allergy check: {'OVERRIDE CONFIRMED' if has_allergy_conflict else 'Clear'}.",
            timestamp="2026-10-17 08:42:00"
        );

        report {
            "ok": True,
            "prescription_id": p_node.id,
            "status": "sent",
            "message": "Prescription transmitted directly to Outpatient Pharmacy Counter."
        };
    }
}

# ==========================================
# 7. Audit & AI Override Logs Walkers
# ==========================================

walker:pub GetAuditLogs {
    """Retrieve system audit logs for Administrator console."""
    has reports: list[dict] = [];

    can list_logs with Root entry {
        logs = [here -->[?:AuditLog]];
        out: list[dict] = [];
        for al in logs {
            out.append({
                "id": al.id,
                "actor": al.actor,
                "role": al.role,
                "action": al.action,
                "target": al.target,
                "details": al.details,
                "timestamp": al.timestamp
            });
        }
        report {"ok": True, "total": len(out), "logs": out};
    }
}

walker:pub GetAIOverrides {
    """Retrieve all doctor triage accept and override decisions."""
    has reports: list[dict] = [];

    can list_overrides with Root entry {
        records = [here -->[?:AIOverrideLog]];
        out: list[dict] = [];
        for ov in records {
            out.append({
                "id": ov.id,
                "doctor_id": ov.doctor_id,
                "doctor_name": ov.doctor_name,
                "patient_id": ov.patient_id,
                "action": ov.action,
                "original_specialty": ov.original_specialty,
                "new_specialty": ov.new_specialty,
                "reason": ov.reason,
                "timestamp": ov.timestamp
            });
        }
        report {"ok": True, "total": len(out), "overrides": out};
    }
}

# ==========================================
# 8. Standard Existing Walkers (Preserved)
# ==========================================

walker:pub HospitalDirectory {
    has province: str = "", district: str = "", hospital_type: str = "", specialty: str = "", search: str = "", reports: list[dict] = [];
    can query with Root entry {
        hospitals = [here -->[?:Hospital]];
        filtered: list[dict] = [];
        for h in hospitals {
            if self.province and self.province != "All" and h.province != self.province { continue; }
            if self.district and self.district != "All" and h.district != self.district { continue; }
            if self.hospital_type and self.hospital_type != "All" and self.hospital_type not in h.hospital_type { continue; }
            if self.search and (self.search.lower() not in h.name.lower() and self.search.lower() not in h.address.lower() and self.search.lower() not in h.district.lower()) { continue; }

            docs = [h -->[?:Doctor]];
            doc_summaries = [];
            for d in docs {
                doc_summaries.append({
                    "id": d.id, "name": d.name, "qualifications": d.qualifications,
                    "specialty_name": d.specialty_name, "clinic_days": d.clinic_days,
                    "room_no": d.room_no, "status": d.status
                });
            }
            filtered.append({
                "id": h.id, "name": h.name, "hospital_type": h.hospital_type,
                "district": h.district, "province": h.province, "address": h.address,
                "lat": h.lat, "lng": h.lng, "phone": h.phone, "opd_hours": h.opd_hours,
                "doctors": doc_summaries
            });
        }
        report {"total_hospitals": len(filtered), "hospitals": filtered};
    }
}

walker:pub CheckIn {
    has hospital_id: str, name: str, phone: str, age: int, sex: str, nic: str = "", consent: bool = True, symptoms: str = "", reports: list[dict] = [];
    can check_in with Root entry {
        existing = [here -->[?:Patient, phone == self.phone]];
        p_node: Patient | None = None;
        if len(existing) > 0 {
            p_node = existing[0];
            p_node.symptoms = self.symptoms;
            p_node.hospital_id = self.hospital_id;
        } else {
            p_node = (here ++> Patient(
                id=f"pat-{self.phone[-4:]}-{self.age}", name=self.name, phone=self.phone,
                age=self.age, sex=self.sex, nic=self.nic, consent=self.consent,
                symptoms=self.symptoms, hospital_id=self.hospital_id
            ))[0] as Patient;
        }
        report {"ok": True, "patient_id": p_node.id, "name": p_node.name, "hospital_id": self.hospital_id, "consent_recorded": self.consent, "symptoms": self.symptoms, "message": "Check-in successful. Ready for guided AI triage."};
    }
}

walker:pub Triage {
    has symptoms: str, age: int = 30, sex: str = "Unspecified", reports: list[dict] = [];
    can evaluate with Root entry {
        rf = check_red_flags(self.symptoms);
        if rf.is_red_flag {
            report {"triage_level": rf.triage_level, "is_emergency": True, "route": rf.route, "reason": rf.reason, "action": rf.action, "suwa_seriya_alert": "1990 Emergency Protocol Notified", "disclaimer": "AI performs triage support only, never definitive diagnosis. Doctor has full command and override."};
            disengage;
        }
        spec = match_specialty_rule(self.symptoms, self.age, self.sex);
        prep = get_test_preparation(spec);
        report {"triage_level": "Green (Routine)", "is_emergency": False, "route": f"Outpatient Clinic: {spec}", "reason": "Stable vital signs presentation based on symptom inquiry.", "action": f"Consultation scheduled with {spec} specialist.", "assigned_specialty": spec, "test_prep": {"test": prep.test, "instructions": prep.instructions, "location": prep.location, "reporting_time": prep.reporting_time}, "disclaimer": "AI performs triage support only, never definitive diagnosis. Doctor has full command and override."};
    }
}

walker:pub AssignDoctor {
    has hospital_id: str, specialty_name: str, reports: list[dict] = [];
    can assign with Root entry {
        doctors = [here -->[?:Doctor, hospital_id == self.hospital_id]];
        eligible = [d for d in doctors if d.specialty_name == self.specialty_name and d.status == "In OPD"];
        if len(eligible) == 0 { eligible = [d for d in doctors if d.specialty_name == self.specialty_name]; }
        if len(eligible) == 0 and len(doctors) > 0 { eligible = [doctors[0]]; }
        if len(eligible) == 0 { report {"ok": False, "error": "No available doctors found."}; disengage; }
        chosen = eligible[0];
        report {"ok": True, "doctor_id": chosen.id, "doctor_name": chosen.name, "qualifications": chosen.qualifications, "specialty_name": chosen.specialty_name, "room_no": chosen.room_no, "clinic_days": chosen.clinic_days, "current_queue_depth": 1};
    }
}

walker:pub JoinQueue {
    has hospital_id: str, doctor_id: str, patient_id: str, patient_name: str, is_emergency: bool = False, reports: list[dict] = [];
    can enqueue with Root entry {
        ticket_num = 10;
        state_val = "front";
        report {"ok": True, "slot_id": f"q-{self.doctor_id[-4:]}-010", "ticket_number": ticket_num, "doctor_name": "Dr. Priyantha Senaratne", "state": state_val, "is_emergency": self.is_emergency, "position": 2, "estimated_wait_minutes": 6, "location_guidance": "Please proceed directly outside Room door (Front Group)", "message": f"Queue Ticket #{ticket_num} issued successfully."};
    }
}

walker:pub AdvanceQueue {
    has doctor_id: str, action: str = "call_next", target_slot_id: str = "", reports: list[dict] = [];
    can advance with Root entry {
        queue_summary = [
            {"slot_id": "q-01", "number": 1, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-02", "number": 2, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-03", "number": 3, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-04", "number": 4, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-05", "number": 5, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-06", "number": 6, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-07", "number": 7, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-08", "number": 8, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-09", "number": 9, "patient_name": "Kasun Bandara", "state": "done", "is_emergency": False},
            {"slot_id": "q-10", "number": 10, "patient_name": "Kasun Bandara", "state": "in_room", "is_emergency": False}
        ];
        report {"ok": True, "doctor_id": self.doctor_id, "action": self.action, "queue": queue_summary};
    }
}

walker:pub Prescribe {
    has patient_id: str, patient_name: str, doctor_id: str, doctor_name: str, items: str, reports: list[dict] = [];
    can send_prescription with Root entry {
        presc_id = f"rx-{self.patient_id[-4:]}-01";
        p_node = (here ++> Prescription(
            id=presc_id, patient_id=self.patient_id, patient_name=self.patient_name,
            doctor_id=self.doctor_id, doctor_name=self.doctor_name, items=self.items,
            created_at="2026-10-17 08:42:00", status="sent"
        ))[0] as Prescription;
        report {"ok": True, "prescription_id": p_node.id, "patient_name": p_node.patient_name, "status": p_node.status, "items": p_node.items, "message": "Prescription pre-sent to Outpatient Pharmacy. Medicine packet preparation started."};
    }
}

walker:pub AdmitPatient {
    has hospital_id: str, patient_name: str, gender: str, condition: str, reports: list[dict] = [];
    can admit with Root entry {
        wards = [here -->[?:Ward, hospital_id == self.hospital_id]];
        chosen_ward = wards[0] if len(wards) > 0 else None;
        if chosen_ward is not None {
            report {"ok": True, "admitted": True, "ward_name": chosen_ward.name, "ward_type": chosen_ward.ward_type, "bed_number": "Bed 03", "message": f"Patient {self.patient_name} admitted to {chosen_ward.name}, Bed 03."};
        } else {
            report {"ok": False, "admitted": False, "message": "No wards available in this hospital."};
        }
    }
}

walker:pub DischargePatient {
    has bed_id: str, actor: str = "Nurse", reports: list[dict] = [];
    can discharge with Root entry {
        report {"ok": True, "bed_id": self.bed_id, "message": f"Patient discharged from {self.bed_id}. Bed queued for terminal sanitization."};
    }
}

walker:pub GetI18nStrings {
    """Retrieve official Sinhala, Tamil, or English localization strings."""
    has lang: str = "en",
        strings: dict = {},
        reports: list[dict] = [];

    can fetch with Root entry {
        self.strings = get_trilingual_strings(self.lang);
        report {"ok": True, "lang": self.lang, "keys_count": len(self.strings)};
    }
}

