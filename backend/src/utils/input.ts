export const limitedText = (value: unknown, maxLength: number): string => {
  return String(value ?? '').trim().slice(0, maxLength);
};

export const optionalLimitedText = (value: unknown, maxLength: number): string | null => {
  const text = limitedText(value, maxLength);
  return text.length > 0 ? text : null;
};

export const boundedNumber = (
  value: unknown,
  fallback: number,
  min: number,
  max: number,
): number => {
  const numberValue = Number(value);
  const finite = Number.isFinite(numberValue) ? numberValue : fallback;
  return Math.min(max, Math.max(min, finite));
};

export const parseHttpUrl = (value: unknown, maxLength = 500): string | null => {
  const text = limitedText(value, maxLength);
  if (!text) return null;

  try {
    const parsed = new URL(text);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      return null;
    }
    return parsed.toString();
  } catch (_) {
    return null;
  }
};

export const productionError = (error: unknown, fallback: string): Record<string, unknown> => {
  if (process.env['NODE_ENV'] === 'production') {
    return { success: false, error: fallback };
  }

  return {
    success: false,
    error: fallback,
    details: error,
  };
};
