"""Sri Lanka Smart Hospital OPD System - Jac Server Entrypoint.

Target: >= 95% Jac Codebase.
Exposes REST Walkers for:
- InitMasterData (graph bootstrap)
- HospitalDirectory (public map & doctors)
- CheckIn (QR patient registration with PDPA consent)
- Triage (Rules-first safety & guided specialty triage)
- AssignDoctor (Specialist routing & wait estimation)
- JoinQueue (Digital queue ticket & 10-patient front group rule)
- AdvanceQueue (Doctor dashboard queue control & patient progression)
- Prescribe (Direct-to-pharmacy e-prescription)
- AdmitPatient (Automated ward & bed assignment)
"""

import from model {
    Hospital, Specialty, Doctor, Patient, QueueSlot,
    LabTest, Prescription, Ward, Bed, Message, AuditLog,
    has_doctor, specializes_in, has_ward, has_bed,
    queued_for, requires, admitted_to, issued, messaged
}
import from rules {
    check_red_flags, get_test_preparation, match_specialty_rule,
    RedFlagResult, TestPrepResult
}
import from walkers {
    InitMasterData, HospitalDirectory, CheckIn, Triage,
    AssignDoctor, JoinQueue, AdvanceQueue, Prescribe, AdmitPatient
}

walker:pub HealthCheck {
    """Service health check and graph readiness probe."""
    has status: str = "healthy",
        reports: list[dict] = [];

    can probe with Root entry {
        hosp_count = len([here -->[?:Hospital]]);
        doc_count = len([here -->[?:Doctor]]);
        queue_count = len([here -->[?:QueueSlot]]);

        report {
            "status": "healthy",
            "system": "Sri Lanka Smart Hospital OPD Platform (Jac 0.16.7)",
            "graph_metrics": {
                "hospitals": hosp_count,
                "doctors": doc_count,
                "active_queue_tickets": queue_count
            },
            "timestamp": "2026-10-17T10:30:00Z"
        };
    }
}

cl {
    import from web.app { App }

    def:pub app() -> JsxElement {
        return <App />;
    }
}

