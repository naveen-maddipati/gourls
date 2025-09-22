import { Guid } from "guid-typescript";

export interface UrlEntry {
  id?: Guid;
  shortName: string;
  longUrl: string;
}
