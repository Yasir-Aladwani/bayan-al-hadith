from deepeval import evaluate
from deepeval.metrics import AnswerRelevancyMetric, FaithfulnessMetric
from deepeval.test_case import LLMTestCase

from app.ragas_test_data import RAGAS_DATASET


def build_test_cases(limit=None):
    test_cases = []

    data = RAGAS_DATASET[:limit] if limit else RAGAS_DATASET

    for item in data:
        test_case = LLMTestCase(
            input=item["question"],
            actual_output=item["answer"],
            expected_output=item["ground_truth"],
            retrieval_context=item["contexts"]
        )

        test_cases.append(test_case)

    return test_cases


def run_deepeval():
    print("=" * 50)
    print("تشغيل DeepEval")
    print("=" * 50)

    test_cases = build_test_cases(limit=5)

    evaluate(
        test_cases=test_cases,
        metrics=[
            AnswerRelevancyMetric(model="gpt-4o-mini"),
            FaithfulnessMetric(model="gpt-4o-mini")
        ]
    )


if __name__ == "__main__":
    run_deepeval()