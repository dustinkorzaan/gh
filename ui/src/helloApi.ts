import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export interface HelloResponse {
  message: string;
}

const apiBaseUrl =
  typeof window === 'undefined' ? '/' : `${window.location.origin}/`;

export const helloApi = createApi({
  reducerPath: 'helloApi',
  baseQuery: fetchBaseQuery({ baseUrl: apiBaseUrl }),
  endpoints: (builder) => ({
    getHello: builder.query<HelloResponse, void>({
      query: () => 'api/gh-api/hello',
    }),
  }),
});

export const { useGetHelloQuery } = helloApi;
