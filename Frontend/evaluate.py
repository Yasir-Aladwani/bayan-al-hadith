"""
HudAI Evaluation using RAGAS
Metrics: Faithfulness, Answer Relevance, Context Precision

Install:
    pip install ragas datasets langchain-anthropic

Usage:
    python evaluate.py
"""

import asyncio
import json
import logging
from pipeline import HadithPipeline

logger = logging.getLogger("HudAI.Eval")

# ─────────────────────────────────────────────
# Test Questions
# ─────────────────────────────────────────────
TEST_QUESTIONS = [
    "ما فضل الصلاة في أول وقتها؟",
    "ما حكم الصيام في شهر رمضان؟",
    "ما فضل قراءة القرآن الكريم؟",
    "ما هي آداب النوم في الإسلام؟",
    "ما فضل الصدقة على الفقراء؟",
]

# ─────────────────────────────────────────────
# Collect Pipeline Results
# ─────────────────────────────────────────────
async def collect_results(questions: list[str]) -> list[dict]:
    pipeline = HadithPipeline()
    results = []

    for q in questions:
        logger.info(f"Evaluating: {q}")
        try:
            result = await pipeline.run(q)
            results.append({
                "question": q,
                "answer": result["answer"],
                "contexts": [h["text"] for h in result["sources"]],
                "ground_truth": "",  # Can be filled manually for full eval
            })
        except Exception as e:
            logger.error(f"Error on question '{q}': {e}")
            results.append({
                "question": q,
                "answer": "خطأ في المعالجة",
                "contexts": [],
                "ground_truth": "",
            })

    return results

# ─────────────────────────────────────────────
# RAGAS Evaluation
# ─────────────────────────────────────────────
def run_ragas_evaluation(results: list[dict]):
    """
    Run RAGAS evaluation on collected results.
    Requires: pip install ragas datasets langchain-anthropic
    """
    try:
        from datasets import Dataset
        from ragas import evaluate
        from ragas.metrics import (
            faithfulness,
            answer_relevancy,
            context_precision,
        )
        from langchain_anthropic import ChatAnthropic
        from ragas.llms import LangchainLLMWrapper

        # Filter results with contexts
        valid = [r for r in results if r["contexts"]]
        if not valid:
            print("❌ No valid results with contexts to evaluate.")
            return

        dataset = Dataset.from_list(valid)

        # Use Claude as judge LLM
        llm = LangchainLLMWrapper(
            ChatAnthropic(model="claude-sonnet-4-20250514", temperature=0)
        )

        print("\n📊 Running RAGAS evaluation...")
        score = evaluate(
            dataset=dataset,
            metrics=[faithfulness, answer_relevancy, context_precision],
            llm=llm,
        )

        print("\n============================")
        print("   HudAI Evaluation Results  ")
        print("============================")
        df = score.to_pandas()
        print(df[["question", "faithfulness", "answer_relevancy", "context_precision"]].to_string())
        print("\n📈 Averages:")
        for col in ["faithfulness", "answer_relevancy", "context_precision"]:
            if col in df.columns:
                print(f"  {col}: {df[col].mean():.4f}")

        # Save results
        df.to_csv("eval_results.csv", index=False)
        print("\n✅ Results saved to eval_results.csv")

    except ImportError as e:
        print(f"\n⚠️  RAGAS not installed: {e}")
        print("Install with: pip install ragas datasets langchain-anthropic")
        print("\nShowing raw pipeline results instead:\n")
        print_raw_results(results)

# ─────────────────────────────────────────────
# Fallback: Print Raw Results
# ─────────────────────────────────────────────
def print_raw_results(results: list[dict]):
    for i, r in enumerate(results, 1):
        print(f"\n{'='*50}")
        print(f"Q{i}: {r['question']}")
        print(f"Answer (first 200 chars): {r['answer'][:200]}...")
        print(f"Contexts retrieved: {len(r['contexts'])}")

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
async def main():
    logging.basicConfig(level=logging.INFO)
    print("🔄 Collecting pipeline results...")
    results = await collect_results(TEST_QUESTIONS)

    print(f"\n✅ Collected {len(results)} results")

    # Save raw results
    with open("raw_eval_results.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print("📁 Raw results saved to raw_eval_results.json")

    run_ragas_evaluation(results)

if __name__ == "__main__":
    asyncio.run(main())
