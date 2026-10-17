"""Sri Lanka Smart Hospital OPD System — Web Application Server."""
import os, json, urllib.parse
from http.server import HTTPServer, SimpleHTTPRequestHandler
import jaclang
from jaclang.jac0core.jaclib import root, spawn
import model
from walkers import (
    InitMasterData, HospitalDirectory, CheckIn, Triage,
    AssignDoctor, JoinQueue, AdvanceQueue, Prescribe, AdmitPatient,
    AuthPatientStep1, AuthPatientStep2, AuthDoctor, AuthStaff, SignOut,
    GetPatientHealth, LogPatientVitals, GetHospitalFacilities, ManageFacility,
    DoctorTriageAction, DoctorPrescribeWithAllergyCheck, OrderFacility,
    DoctorUpdateProfile, GetDoctorPublicProfile, AdminManageDoctor,
    GetAuditLogs, GetAIOverrides, GetDoctorPatients, GetI18nStrings
)

PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
WEB_DIR = os.path.join(BASE_DIR, "web")

def init_jac_graph():
    try:
        spawn(root(), InitMasterData(data_path=os.path.join(BASE_DIR, "data", "sri_lanka_hospitals.json")))
    except Exception as e:
        print("[JAC ERROR]", e)

class SmartHospitalRequestHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path); params = urllib.parse.parse_qs(parsed.query); p = parsed.path
        try:
            if p == "/api/health": return self.send_json(200, {"status": "healthy", "system": "Sri Lanka Smart Hospital OPD Platform"})
            elif p == "/api/i18n": return self.send_json(200, getattr(spawn(root(), GetI18nStrings(lang=params.get("lang", ["en"])[0])), "strings", {}))
            elif p == "/api/hospitals": return self.send_json(200, (spawn(root(), HospitalDirectory(province=params.get("province", [""])[0], district=params.get("district", [""])[0], hospital_type=params.get("hospital_type", [""])[0], specialty=params.get("specialty", [""])[0], search=params.get("search", [""])[0])).reports or [{"hospitals": []}])[0])
            elif p == "/api/facilities": return self.send_json(200, (spawn(root(), GetHospitalFacilities(hospital_id=params.get("hospital_id", ["hosp-nhsl-01"])[0], category=params.get("category", ["All"])[0], search=params.get("search", [""])[0])).reports or [{"facilities": []}])[0])
            elif p == "/api/doctor/profile": return self.send_json(200, (spawn(root(), GetDoctorPublicProfile(doctor_id=params.get("doctor_id", ["doc-nhsl-02"])[0])).reports or [{"ok": False}])[0])
            elif p == "/api/patient/health": return self.send_json(200, (spawn(root(), GetPatientHealth(patient_id=params.get("patient_id", ["pat-4567-34"])[0], actor_role=params.get("actor_role", ["patient"])[0])).reports or [{"ok": False}])[0])
            elif p == "/api/doctor/patients": return self.send_json(200, (spawn(root(), GetDoctorPatients(doctor_id=params.get("doctor_id", ["doc-nhsl-02"])[0], filter_state=params.get("filter", ["All"])[0])).reports or [{"patients": []}])[0])
            elif p == "/api/admin/audit_logs": return self.send_json(200, (spawn(root(), GetAuditLogs()).reports or [{"logs": []}])[0])
            elif p == "/api/admin/ai_overrides": return self.send_json(200, (spawn(root(), GetAIOverrides()).reports or [{"overrides": []}])[0])
            super().do_GET()
        except Exception as e: self.send_json(500, {"ok": False, "error": str(e)})

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path); length = int(self.headers.get("Content-Length", 0)); p = parsed.path
        body = json.loads(self.rfile.read(length).decode("utf-8")) if length > 0 else {}
        try:
            if p == "/api/auth/patient/step1": res = spawn(root(), AuthPatientStep1(phone=body.get("phone", ""), nic=body.get("nic", ""), hospital_id=body.get("hospital_id", "hosp-nhsl-01")))
            elif p == "/api/auth/patient/step2": res = spawn(root(), AuthPatientStep2(phone=body.get("phone", ""), nic=body.get("nic", ""), otp=body.get("otp", ""), consent=bool(body.get("consent", False)), hospital_id=body.get("hospital_id", "hosp-nhsl-01")))
            elif p == "/api/auth/doctor": res = spawn(root(), AuthDoctor(email=body.get("email", ""), password=body.get("password", ""), remember_me=bool(body.get("remember_me", False))))
            elif p == "/api/auth/staff": res = spawn(root(), AuthStaff(staff_id=body.get("staff_id", ""), password=body.get("password", ""), hospital_id=body.get("hospital_id", "hosp-nhsl-01"), role=body.get("role", "nurse")))
            elif p == "/api/auth/signout": res = spawn(root(), SignOut(actor=body.get("actor", "User"), role=body.get("role", "guest")))
            elif p == "/api/patient/log_vitals": res = spawn(root(), LogPatientVitals(patient_id=body.get("patient_id", "pat-4567-34"), actor=body.get("actor", "Kasun Bandara"), bp=body.get("bp", ""), glucose=body.get("glucose", ""), hr=body.get("hr", "74 bpm")))
            elif p == "/api/facilities/manage": res = spawn(root(), ManageFacility(hospital_id=body.get("hospital_id", "hosp-nhsl-01"), facility_key=body.get("facility_key", ""), status=body.get("status", "available"), current_wait_minutes=int(body.get("current_wait_minutes", 15)), next_slot=body.get("next_slot", "Tomorrow 09:00 AM"), actor=body.get("actor", "Staff")))
            elif p == "/api/doctor/triage_action": res = spawn(root(), DoctorTriageAction(doctor_id=body.get("doctor_id", "doc-nhsl-02"), doctor_name=body.get("doctor_name", "Dr. Priyantha Senaratne"), patient_id=body.get("patient_id", "pat-4567-34"), action=body.get("action", "accept"), new_specialty=body.get("new_specialty", ""), new_priority=body.get("new_priority", ""), reason=body.get("reason", "")))
            elif p == "/api/doctor/prescribe": res = spawn(root(), DoctorPrescribeWithAllergyCheck(patient_id=body.get("patient_id", "pat-4567-34"), patient_name=body.get("patient_name", "Kasun Bandara"), doctor_id=body.get("doctor_id", "doc-nhsl-02"), doctor_name=body.get("doctor_name", "Dr. Priyantha Senaratne"), items=body.get("items", ""), confirmed_override=bool(body.get("confirmed_override", False))))
            elif p == "/api/doctor/order_facility": res = spawn(root(), OrderFacility(patient_id=body.get("patient_id", "pat-4567-34"), facility_key=body.get("facility_key", ""), ordered_by=body.get("ordered_by", "Dr. Priyantha Senaratne"), priority=body.get("priority", "routine")))
            elif p == "/api/doctor/update_profile": res = spawn(root(), DoctorUpdateProfile(doctor_id=body.get("doctor_id", "doc-nhsl-02"), bio=body.get("bio", ""), languages=body.get("languages", ["Sinhala", "English"]), clinic_days=body.get("clinic_days", ""), status=body.get("status", "In OPD")))
            elif p == "/api/admin/manage_doctor": res = spawn(root(), AdminManageDoctor(action=body.get("action", "add"), doctor_id=body.get("doctor_id", ""), name=body.get("name", ""), specialty_name=body.get("specialty_name", ""), qualifications=body.get("qualifications", ""), hospital_id=body.get("hospital_id", "hosp-nhsl-01"), room_no=body.get("room_no", ""), slmc_reg=body.get("slmc_reg", ""), staff_id=body.get("staff_id", ""), work_email=body.get("work_email", ""), work_phone=body.get("work_phone", "")))
            elif p == "/api/checkin": res = spawn(root(), CheckIn(hospital_id=body.get("hospital_id", ""), name=body.get("name", ""), phone=body.get("phone", ""), age=int(body.get("age", 30)), sex=body.get("sex", "Unspecified"), nic=body.get("nic", ""), consent=bool(body.get("consent", True)), symptoms=body.get("symptoms", "")))
            elif p == "/api/triage": res = spawn(root(), Triage(symptoms=body.get("symptoms", ""), age=int(body.get("age", 30)), sex=body.get("sex", "Unspecified")))
            else: return self.send_json(404, {"error": "Endpoint not found"})
            return self.send_json(200, res.reports[0] if res.reports else {"ok": True})
        except Exception as e: self.send_json(500, {"ok": False, "error": str(e)})

    def send_json(self, code, data):
        self.send_response(code); self.send_header("Content-Type", "application/json"); self.send_header("Access-Control-Allow-Origin", "*"); self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

def main():
    init_jac_graph()
    httpd = HTTPServer(("", PORT), SmartHospitalRequestHandler)
    print(f"[SERVER] Smart Hospital OPD Server running on http://localhost:{PORT}")
    try: httpd.serve_forever()
    except KeyboardInterrupt: httpd.server_close()

if __name__ == "__main__": main()
