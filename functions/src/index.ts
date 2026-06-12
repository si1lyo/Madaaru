import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Anthropic from "@anthropic-ai/sdk";

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

interface ReceiptItem {
  name: string;
  price: number;
  quantity?: number;
  genre: string;
}

interface ReceiptData {
  date?: string;
  store_name?: string;
  total?: number;
  items: ReceiptItem[];
}

export const analyzeReceipt = onCall(
  {
    secrets: [anthropicApiKey],
    timeoutSeconds: 120,
    memory: "512MiB",
    region: "asia-northeast1",
  },
  async (request): Promise<ReceiptData> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }

    const { imageBase64, mediaType } = request.data as {
      imageBase64: string;
      mediaType: "image/jpeg" | "image/png" | "image/gif" | "image/webp";
    };

    if (!imageBase64 || !mediaType) {
      throw new HttpsError(
        "invalid-argument",
        "imageBase64 と mediaType が必要です。"
      );
    }

    const client = new Anthropic({
      apiKey: anthropicApiKey.value(),
    });

    const response = await client.messages.create({
      model: "claude-opus-4-8",
      max_tokens: 2048,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: mediaType,
                data: imageBase64,
              },
            },
            {
              type: "text",
              text: `このレシート画像から以下の情報をJSON形式で抽出してください。

必ず以下のJSON構造で返してください（コードブロックなし、JSONのみ）:
{
  "date": "購入日 (YYYY-MM-DD形式、不明な場合はnull)",
  "store_name": "店名（不明な場合はnull）",
  "total": 合計金額の数値（不明な場合はnull）,
  "items": [
    {
      "name": "商品名",
      "price": 価格の数値,
      "quantity": 数量の数値（不明な場合は1）,
      "genre": "食品・日用品・その他のいずれか"
    }
  ]
}

注意:
- 金額は数値のみ（円マークや記号なし）
- 日付が読み取れない場合は null
- 商品名は日本語のまま
- itemsは必ず配列（空でも可）
- genreは必ず「食品」「日用品」「その他」のいずれかにすること`,
            },
          ],
        },
      ],
    });

    const textContent = response.content.find((c) => c.type === "text");
    if (!textContent || textContent.type !== "text") {
      throw new HttpsError("internal", "レシートの解析に失敗しました。");
    }

    try {
      const parsed = JSON.parse(textContent.text) as ReceiptData;
      return parsed;
    } catch {
      const jsonMatch = textContent.text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]) as ReceiptData;
      }
      throw new HttpsError(
        "internal",
        "レスポンスのJSONパースに失敗しました。"
      );
    }
  }
);
