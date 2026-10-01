import { useGetHelloQuery } from './helloApi';

export default function Hello() {
  const { data, isError, isLoading } = useGetHelloQuery();

  if (isLoading) {
    return <p role="status">Loading greeting…</p>;
  }

  if (isError) {
    return <p role="alert">Unable to load greeting.</p>;
  }

  return (
    <main>
      <h1>{data?.message}</h1>
    </main>
  );
}
