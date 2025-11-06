import { Guid } from "guid-typescript";

export interface UrlEntry {
  id?: Guid;
  shortName: string;
  longUrl: string;
  createdBy?: string;
  createdAt?: Date;
  updatedAt?: Date;
  updatedBy?: string;
  isSystemEntry?: boolean;
  canEdit?: boolean;
  canDelete?: boolean;
}

export interface CreateUrlRequest {
  shortName: string;
  longUrl: string;
}

export interface UpdateUrlRequest {
  shortName: string;
  longUrl: string;
}
