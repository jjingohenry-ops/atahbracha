type GestationReference = {
  gestationDays: number;
  checkupOffsetsBeforeDue: number[];
};

const DEFAULT_REFERENCE: GestationReference = {
  gestationDays: 150,
  checkupOffsetsBeforeDue: [30, 14],
};

const SPECIES_REFERENCES: Record<string, GestationReference> = {
  CATTLE: { gestationDays: 283, checkupOffsetsBeforeDue: [60, 30, 14] },
  GOAT: { gestationDays: 150, checkupOffsetsBeforeDue: [30, 14] },
  SHEEP: { gestationDays: 147, checkupOffsetsBeforeDue: [30, 14] },
  PIG: { gestationDays: 114, checkupOffsetsBeforeDue: [21, 7] },
  HORSE: { gestationDays: 340, checkupOffsetsBeforeDue: [90, 30, 14] },
  RABBIT: { gestationDays: 31, checkupOffsetsBeforeDue: [10, 3] },
  DOG: { gestationDays: 63, checkupOffsetsBeforeDue: [14, 7] },
  CAT: { gestationDays: 65, checkupOffsetsBeforeDue: [14, 7] },
};

const BREED_OVERRIDES: Record<string, Partial<Record<string, GestationReference>>> = {
  CATTLE: {
    ankole: { gestationDays: 285, checkupOffsetsBeforeDue: [60, 30, 14] },
    holstein: { gestationDays: 279, checkupOffsetsBeforeDue: [60, 30, 14] },
    'holstein-friesian': { gestationDays: 279, checkupOffsetsBeforeDue: [60, 30, 14] },
    jersey: { gestationDays: 279, checkupOffsetsBeforeDue: [60, 30, 14] },
  },
};

const normalizeBreed = (breed?: string | null): string => {
  return (breed || '').trim().toLowerCase();
};

export const getGestationReference = (species: string, breed?: string | null): GestationReference => {
  const normalizedSpecies = species.trim().toUpperCase();
  const normalizedBreed = normalizeBreed(breed);
  const breedReference = normalizedBreed
    ? BREED_OVERRIDES[normalizedSpecies]?.[normalizedBreed]
    : undefined;

  return breedReference || SPECIES_REFERENCES[normalizedSpecies] || DEFAULT_REFERENCE;
};

export const addDays = (date: Date, days: number): Date => {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
};
