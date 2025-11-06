import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { UrlEntry, CreateUrlRequest, UpdateUrlRequest } from '../models/url-entry.model';
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

  addUrl(request: CreateUrlRequest): Observable<UrlEntry> {
    return this.http.post<UrlEntry>(this.apiUrl, request).pipe(
  catchError((error: any) => {
        console.error('Error adding URL:', error);
        throw error;
      })
    );
  }

  updateUrl(id: Guid, request: UpdateUrlRequest): Observable<UrlEntry> {
    return this.http.put<UrlEntry>(`${this.apiUrl}/${id}`, request).pipe(
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

  getByShortName(shortName: string): Observable<UrlEntry> {
    return this.http.get<UrlEntry>(`${this.apiUrl}/${encodeURIComponent(shortName)}`).pipe(
      catchError((error: any) => {
        console.error('Error getting URL by short name:', error);
        throw error;
      })
    );
  }

  getCurrentUser(): Observable<{name: string, isAuthenticated: boolean}> {
    return this.http.get<{name: string, isAuthenticated: boolean}>(`${this.apiUrl}/user`).pipe(
      catchError((error: any) => {
        console.error('Error getting current user:', error);
        throw error;
      })
    );
  }
}
