from sentence_transformers import util
from ai_model import model


def check_duplicate(new_report: str, existing_reports: list):
    # New report ko vector me convert karo
    new_embedding = model.encode(new_report, convert_to_tensor=True)

    best_score = 0
    best_match = None

    # Har existing report se compare karo
    for report in existing_reports:
        report_embedding = model.encode(report, convert_to_tensor=True)

        score = util.cos_sim(new_embedding, report_embedding).item()

        if score > best_score:
            best_score = score
            best_match = report

    return {
        "duplicate": best_score > 0.80,
        "similarity": round(best_score, 2),
        "matched_report": best_match
    }