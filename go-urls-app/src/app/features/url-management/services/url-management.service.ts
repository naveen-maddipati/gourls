import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { UrlEntry } from '../models/url-entry.model';
import { Base_Url } from '../../../core/constants';
import { Guid } from 'guid-typescript';

@Injectable({ providedIn: 'root' })
export class UrlManagementService {
  private apiUrl = Base_Url + 'api/urls';

  constructor(private http: HttpClient) {}

  getUrls(): Observable<UrlEntry[]> {
    return this.http.get<UrlEntry[]>(this.apiUrl).pipe(
      // Log errors for debugging
  catchError((error: any) => {
        console.error('Error fetching URLs:', error);
        throw error;
      })
    );
  }

  addUrl(entry: UrlEntry): Observable<UrlEntry> {
    return this.http.post<UrlEntry>(this.apiUrl, entry).pipe(
  catchError((error: any) => {
        console.error('Error adding URL:', error);
        throw error;
      })
    );
  }

  updateUrl(entry: UrlEntry): Observable<UrlEntry> {
    return this.http.put<UrlEntry>(`${this.apiUrl}/${entry.id}`, entry).pipe(
  catchError((error: any) => {
        console.error('Error updating URL:', error);
        throw error;
      })
    );
  }

  deleteUrl(id: Guid): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`).pipe(
  catchError((error: any) => {
        console.error('Error deleting URL:', error);
        throw error;
      })
    );
  }

  searchShortName(keyword: string): Observable<UrlEntry[]> {
    return this.http.get<UrlEntry[]>(`${this.apiUrl}/search?shortName=${encodeURIComponent(keyword)}`).pipe(
  catchError((error: any) => {
        console.error('Error searching URLs:', error);
        throw error;
      })
    );
  }
}
