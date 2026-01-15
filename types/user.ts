export type User = {
  uid: string;

  username: string;
  name: string;

  avatar?: string;

  bio?: string;

  isPrivate?: boolean;

  createdAt?: number;
};
