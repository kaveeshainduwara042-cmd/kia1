"""Object-Spatial Graph Data Model for Sri Lanka Smart Hospital OPD System.

Expanded with:
- Config constant APP_NAME
- Doctor public & internal profile fields
- Facility node & offers/requires edges (including MRI, CT, Endoscopy, etc.)
- Patient health records: conditions, vitals, allergies, medicines, labs, visits
- UserAccount node & AuditLog node
- AIOverrideLog records
"""

# Config constant for system branding
glob APP_NAME: str = "Smart Hospital OPD";

# ==========================================
# Graph Nodes
# ==========================================

node Hospital {
    has id: str,
        name: str,
        hospital_type: str,     # Teaching, Provincial General, District General, Base, Divisional
        district: str,
        province: str,
        address: str,
        lat: float,
        lng: float,
        phone: str,
        opd_hours: str;
}

node Specialty {
    has id: str,
        name: str,
        description: str;
}

node Doctor {
    has id: str,
        name: str,
        qualifications: str,
        specialty_name: str,
        sub_specialty: str = "General",
        experience_years: int = 10,
        languages: list[str] = ["Sinhala", "English"],
        hospital_id: str = "",
        hospital_name: str = "",
        room_no: str = "",
        clinic_days: str = "",
        status: str = "In OPD", # In OPD, On break, Off duty
        bio: str = "Consultant medical specialist providing dedicated outpatient clinical care.",
        ordered_services: list[str] = ["ECG", "Full Blood Count", "Ultrasound Abdomen"],
        # Internal fields (never shown to patients or public)
        slmc_reg: str = "SLMC-00000",
        staff_id: str = "STF-DOC-000",
        work_email: str = "doctor@example.lk",
        work_phone: str = "+94 11 000 0000";
}

node Facility {
    has key: str,
        name: str,
        category: str,          # Imaging, Cardiac, Laboratory, Treatment, Services
        location: str,          # Building and level
        opening_hours: str,
        typical_duration: str,
        requires_referral: bool = True,
        scheduled: bool = False, # appointment slot vs walk-in
        about: str = "",
        prep_instructions: list[str] = [],
        bring: list[str] = [];
}

node Patient {
    has id: str,
        name: str,
        phone: str,
        age: int,
        sex: str,
        nic: str = "",
        consent: bool = True,
        symptoms: str = "",
        triage_level: str = "Green (Routine)", # Red (Emergency), Yellow (Urgent), Green (Routine)
        hospital_id: str = "",
        # Patient Health Records
        conditions: list[dict] = [],
        vitals: dict = {},
        allergies: list[str] = [],
        medicines: list[dict] = [],
        lab_results: list[dict] = [],
        visit_history: list[dict] = [],
        tests_and_scans: list[dict] = [];
}

node QueueSlot {
    has slot_id: str,
        number: int,
        hospital_id: str,
        doctor_id: str,
        doctor_name: str,
        patient_id: str,
        patient_name: str,
        check_in_time: str,
        state: str = "waiting", # waiting, front, in_room, done, skipped
        is_emergency: bool = False;
}

node LabTest {
    has id: str,
        name: str,
        prep_instructions: str,
        location: str;
}

node Prescription {
    has id: str,
        patient_id: str,
        patient_name: str,
        doctor_id: str,
        doctor_name: str,
        items: str, # JSON or string of medicines & doses
        created_at: str,
        status: str = "sent"; # sent, preparing, ready, collected
}

node Ward {
    has id: str,
        hospital_id: str,
        name: str,
        ward_type: str, # Medical, Surgical, Paediatric, Maternity, ICU
        gender_category: str, # Male, Female, Mixed, Children
        capacity: int;
}

node Bed {
    has id: str,
        ward_id: str,
        number: str,
        status: str = "free"; # free, occupied, cleaning
}

node Message {
    has id: str,
        from_doctor: str,
        to_doctor: str,
        body: str,
        sent_at: str,
        patient_ref: str = "";
}

node AuditLog {
    has id: str,
        actor: str,
        role: str,
        action: str,
        target: str,
        details: str = "",
        timestamp: str = "";
}

node AIOverrideLog {
    has id: str,
        doctor_id: str,
        doctor_name: str,
        patient_id: str,
        action: str,            # accept or override
        original_specialty: str = "",
        new_specialty: str = "",
        original_priority: str = "",
        new_priority: str = "",
        reason: str = "",
        timestamp: str = "";
}

node UserAccount {
    has id: str,
        username: str,          # phone, email, or staff_id
        role: str,              # patient, doctor, nurse, pharmacist, admin
        hospital_id: str = "",
        specialty: str = "",
        token: str = "";
}

# ==========================================
# Graph Edges
# ==========================================

edge has_doctor: Hospital --> Doctor {}
edge specializes_in: Doctor --> Specialty {}
edge has_ward: Hospital --> Ward {}
edge has_bed: Ward --> Bed {}
edge queued_for: Patient --> Doctor {}
edge requires: Patient --> LabTest {}
edge admitted_to: Patient --> Bed {}
edge issued: Doctor --> Prescription {}
edge messaged: Doctor --> Doctor {}

# Facilities edges
edge offers: Hospital --> Facility {
    has status: str = "available",          # available, busy, out_of_service
        current_wait_minutes: int = 15,
        next_slot: str = "Today 10:30 AM";
}

edge requires_facility: Patient --> Facility {
    has ordered_by: str = "",
        priority: str = "routine",           # routine, urgent, stat
        status: str = "ordered",             # ordered, prep, completed
        date: str = "2026-10-17";
}
