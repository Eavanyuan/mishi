import { create } from 'zustand';

export interface Poem {
  poem_id: number;
  title: string;
  author: string;
  dynasty: string;
  preview_line: string;
  distance: number;
  season_tag: string;
}

interface PoemState {
  poems: Poem[];
  recentPoems: Poem[];
  favoritePoemIds: number[];
  addPoems: (poems: Poem[]) => void;
  addToRecent: (poem: Poem) => void;
  toggleFavorite: (poemId: number) => void;
  clearRecent: () => void;
}

export const usePoemStore = create<PoemState>((set) => ({
  poems: [],
  recentPoems: [],
  favoritePoemIds: [],
  addPoems: (poems) =>
    set((state) => {
      const newPoems = poems.filter(
        (p) => !state.poems.some((existing) => existing.poem_id === p.poem_id)
      );
      return { poems: [...state.poems, ...newPoems] };
    }),
  addToRecent: (poem) =>
    set((state) => {
      const filtered = state.recentPoems.filter((p) => p.poem_id !== poem.poem_id);
      return { recentPoems: [poem, ...filtered].slice(0, 10) };
    }),
  toggleFavorite: (poemId) =>
    set((state) => {
      const isFavorite = state.favoritePoemIds.includes(poemId);
      return {
        favoritePoemIds: isFavorite
          ? state.favoritePoemIds.filter((id) => id !== poemId)
          : [...state.favoritePoemIds, poemId],
      };
    }),
  clearRecent: () => set({ recentPoems: [] }),
}));