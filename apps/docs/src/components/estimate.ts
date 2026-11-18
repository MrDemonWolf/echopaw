export type UsageAssumptions = {
  replies: number;
  inputTokens: number;
  outputTokens: number;
  spokenCharacters: number;
  inputPrice: number;
  outputPrice: number;
  speechPrice: number;
};

export function estimateCost(values: UsageAssumptions) {
  if (Object.values(values).some((value) => !Number.isFinite(value) || value < 0)) return null;
  const dialogue = values.replies * (
    values.inputTokens * values.inputPrice + values.outputTokens * values.outputPrice
  ) / 1_000_000;
  const speech = values.replies * values.spokenCharacters * values.speechPrice / 1_000;
  if (!Number.isFinite(dialogue + speech)) return null;
  return { dialogue, speech, total: dialogue + speech };
}
