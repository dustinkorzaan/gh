import { configureStore } from '@reduxjs/toolkit';
import { helloApi } from './helloApi';

export function createAppStore() {
  return configureStore({
    reducer: {
      [helloApi.reducerPath]: helloApi.reducer,
    },
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware().concat(helloApi.middleware),
  });
}
