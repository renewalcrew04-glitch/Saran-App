import { create } from "zustand";

type PlantStage = "seed" | "seedling" | "tree";

type Plant = {
  id: number;
  plantedAt: string;
  wateredAt: string;
};

type GardenState = {
  plants: Plant[];
  lastSeeded?: string;
  lastWatered?: string;
  plantSeed: () => void;
  water: () => void;
  getStage: (plant: Plant) => PlantStage;
};

export const useGardenStore = create<GardenState>((set, get) => ({
  plants: [],
  lastSeeded: undefined,
  lastWatered: undefined,

  plantSeed: () => {
    const today = new Date().toDateString();
    if (get().lastSeeded === today) return;

    set((state) => ({
      plants: [
        ...state.plants,
        {
          id: Date.now(),
          plantedAt: new Date().toISOString(),
          wateredAt: new Date().toISOString(),
        },
      ],
      lastSeeded: today,
    }));
  },

  water: () => {
    const today = new Date().toDateString();
    if (get().lastWatered === today) return;

    set((state) => ({
      plants: state.plants.map((p) => ({
        ...p,
        wateredAt: new Date().toISOString(),
      })),
      lastWatered: today,
    }));
  },

  getStage: (plant) => {
    const days =
      Math.floor(
        (Date.now() - new Date(plant.plantedAt).getTime()) /
          (1000 * 60 * 60 * 24)
      );

    if (days === 0) return "seed";
    if (days === 1) return "seedling";
    return "tree";
  },
}));
