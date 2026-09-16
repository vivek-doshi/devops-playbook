interface Token {
  text: string;
  type: string;
}

interface TokenizedLine {
  tokens: Token[];
  width: number;
}

interface InitMessage {
  type: "INIT";
  canvas: OffscreenCanvas;
  text: string;
  pixelRatio: number;
  width: number;
  height: number;
}

interface ResizeMessage {
  type: "RESIZE";
  width: number;
  height: number;
  pixelRatio: number;
}

type WorkerMessage = InitMessage | ResizeMessage;

interface WorkerResponse {
  success: boolean;
  error?: string;
}

// Color palette for dark mode theme
const colorPalette: Record<string, string> = {
  key: "#E06C75", // Red/Pink
  string: "#98C379", // Green
  number: "#D19A66", // Orange
  boolean: "#D19A66", // Orange
  comment: "#5C6370", // Grey
  default: "#ABB2BF", // Light Grey
};

// Internal state
let state = {
  canvas: null as OffscreenCanvas | null,
  text: "",
  pixelRatio: 1,
  width: 0,
  height: 0,
  fontSize: 18,
  fontFamily: '"Courier New", monospace',
  lineHeight: 26,
};

// Simple YAML tokenizer
const tokenizeYamlLine = (line: string): Token[] => {
  const tokens: Token[] = [];
  let remaining = line;

  // Remove leading whitespace
  remaining = remaining.trimStart();

  while (remaining.length > 0) {
    // Comment detection
    if (remaining.startsWith("#")) {
      const commentEnd = remaining.indexOf("\n");
      if (commentEnd === -1) {
        tokens.push({ text: remaining, type: "comment" });
        break;
      }
      tokens.push({
        text: remaining.substring(0, commentEnd),
        type: "comment",
      });
      remaining = remaining.substring(commentEnd + 1);
      continue;
    }

    // Boolean detection
    if (remaining.startsWith("true") || remaining.startsWith("false")) {
      const boolMatch = remaining.match(/^(true|false)(\s|$)/);
      if (boolMatch) {
        tokens.push({ text: boolMatch[1], type: "boolean" });
        remaining = remaining.substring(boolMatch[0].length);
        continue;
      }
    }

    // Number detection
    const numberMatch = remaining.match(/^(\d+\.?\d*)(\s|$)/);
    if (numberMatch) {
      tokens.push({ text: numberMatch[1], type: "number" });
      remaining = remaining.substring(numberMatch[0].length);
      continue;
    }

    // String detection (single or double quotes)
    const stringMatch = remaining.match(/^(['"])([^'"]*)\1/);
    if (stringMatch) {
      tokens.push({ text: stringMatch[2], type: "string" });
      remaining = remaining.substring(stringMatch[0].length);
      continue;
    }

    // Key detection (word followed by colon)
    const keyMatch = remaining.match(/^\s*([\w.-]+):/);
    if (keyMatch) {
      tokens.push({ text: keyMatch[1], type: "key" });
      remaining = remaining.substring(keyMatch[0].length);
      continue;
    }

    // Default: remaining whitespace or unclassified punctuation
    const defaultMatch = remaining.match(/^\s*([^\s])/);
    if (defaultMatch) {
      tokens.push({ text: defaultMatch[1], type: "default" });
      remaining = remaining.substring(1);
      continue;
    }

    // Default: whitespace
    const whitespaceMatch = remaining.match(/^\s+/);
    if (whitespaceMatch) {
      tokens.push({ text: whitespaceMatch[0], type: "default" });
      remaining = remaining.substring(whitespaceMatch[0].length);
      continue;
    }

    // Default: remaining text
    if (remaining.length > 0) {
      tokens.push({ text: remaining, type: "default" });
      break;
    }
  }

  return tokens;
};

// Tokenize entire content
const tokenizeYamlContent = (
  content: string,
  ctx: OffscreenCanvasRenderingContext2D,
): TokenizedLine[] => {
  const lines: TokenizedLine[] = [];
  const paragraphs = content.split("\n");

  for (const paragraph of paragraphs) {
    if (paragraph.trim() === "") {
      lines.push({ tokens: [], width: 0 });
      continue;
    }

    const tokens = tokenizeYamlLine(paragraph);
    const width = tokens.reduce((sum, token) => {
      const metrics = ctx.measureText(token.text);
      return sum + metrics.width;
    }, 0);

    lines.push({ tokens, width });
  }

  return lines;
};

// Render function
const render = () => {
  if (!state.canvas || !state.text) {
    return;
  }

  try {
    const ctx = state.canvas.getContext("2d");
    if (!ctx) {
      self.postMessage({
        success: false,
        error: "Failed to get context",
      } as WorkerResponse);
      return;
    }

    // High-DPI support
    ctx.scale(state.pixelRatio, state.pixelRatio);

    // Font configuration
    ctx.font = `${state.fontSize}px ${state.fontFamily}`;
    ctx.textBaseline = "top";
    ctx.fillStyle = "#ffffff";
    ctx.strokeStyle = "#ffffff";

    // Tokenize content
    const tokenizedLines = tokenizeYamlContent(state.text, ctx);

    // Calculate total height
    const totalHeight = tokenizedLines.reduce((sum) => {
      return sum + state.lineHeight;
    }, 0);

    // Update canvas height
    state.canvas.height = totalHeight * state.pixelRatio;

    // Render tokenized text
    tokenizedLines.forEach((line, index) => {
      if (line.tokens.length === 0) {
        ctx.fillText("", 0, index * state.lineHeight);
        return;
      }

      let currentX = 0;
      const padding = 4;

      for (const token of line.tokens) {
        const color = colorPalette[token.type] || colorPalette.default;
        ctx.fillStyle = color;

        const metrics = ctx.measureText(token.text);

        if (currentX + metrics.width > state.width && currentX > padding) {
          // Wrap to next line
          ctx.fillStyle = color;
          ctx.fillText(token.text, currentX, index * state.lineHeight);
          currentX = metrics.width;
        } else {
          ctx.fillStyle = color;
          ctx.fillText(token.text, currentX, index * state.lineHeight);
          currentX += metrics.width;
        }
      }
    });

    self.postMessage({ success: true } as WorkerResponse);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    self.postMessage({ success: false, error: message } as WorkerResponse);
  }
};

self.onmessage = (e: MessageEvent<WorkerMessage>) => {
  const message = e.data;

  if (message.type === "INIT") {
    // Store state, preserving font defaults
    state = {
      ...state,
      canvas: message.canvas,
      text: message.text,
      pixelRatio: message.pixelRatio,
      width: message.width,
      height: message.height,
    };

    // Call render
    render();
  } else if (message.type === "RESIZE") {
    // Update state
    state.pixelRatio = message.pixelRatio;
    state.width = message.width;
    state.height = message.height;

    // Call render
    render();
  }
};
