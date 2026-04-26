import json

from ragas import evaluate
from ragas.metrics import Faithfulness, ResponseRelevancy
from ragas.dataset_schema import SingleTurnSample, EvaluationDataset

from langchain_openai import ChatOpenAI, OpenAIEmbeddings

from app.config import OPENAI_API_KEY
from app.ragas_test_data import RAGAS_DATASET


llm = ChatOpenAI(
    model="gpt-4o-mini",
    api_key=OPENAI_API_KEY
)

embeddings = OpenAIEmbeddings(
    api_key=OPENAI_API_KEY
)


def build_ragas_dataset():
    samples = []

    for i, item in enumerate(RAGAS_DATASET):
        print(f"[{i + 1}/{len(RAGAS_DATASET)}] تجهيز السؤال:")
        print(item["question"])

        sample = SingleTurnSample(
            user_input=item["question"],
            response=item["answer"],
            retrieved_contexts=item["contexts"],
            reference=item["ground_truth"]
        )

        samples.append(sample)

    return EvaluationDataset(samples=samples)


def run_evaluation():
    print("=" * 60)
    print("بدء تقييم RAGAS")
    print("=" * 60)

    dataset = build_ragas_dataset()

    scores = evaluate(
        dataset=dataset,
        metrics=[
            Faithfulness(),
            ResponseRelevancy()
        ],
        llm=llm,
        embeddings=embeddings
    )

    df = scores.to_pandas()

    print("\n" + "=" * 60)
    print("نتائج RAGAS")
    print("=" * 60)

    print(df[[
        "user_input",
        "faithfulness",
        "answer_relevancy"
    ]].to_string())

    print("\n" + "=" * 60)
    print("الملخص النهائي")
    print("=" * 60)

    print(f"Faithfulness: {df['faithfulness'].mean():.2f}")
    print(f"Answer Relevancy: {df['answer_relevancy'].mean():.2f}")

    df.to_csv("eval_results.csv", index=False)

    with open("eval_results.json", "w", encoding="utf-8") as f:
        json.dump(df.to_dict(orient="records"), f, ensure_ascii=False, indent=2)

    print("\nتم حفظ النتائج:")
    print("eval_results.csv")
    print("eval_results.json")


if __name__ == "__main__":
    run_evaluation()