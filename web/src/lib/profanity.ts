import { Profanity } from "@2toad/profanity";
import {
  RegExpMatcher,
  englishDataset,
  englishRecommendedTransformers,
} from "obscenity";

const profanity = new Profanity({
  languages: ["ar", "zh", "en", "fr", "de", "hi", "it", "ja", "ko", "pt", "ru", "es"],
});

const obscenityMatcher = new RegExpMatcher({
  ...englishDataset.build(),
  ...englishRecommendedTransformers,
});

export function isProfane(text: string): boolean {
  return profanity.exists(text) || obscenityMatcher.hasMatch(text);
}
