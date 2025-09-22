import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { Base_Url } from '../constants';

@Injectable({ providedIn: 'root' })
export class UserService {
  constructor(private http: HttpClient) {}

  getUserName(): Observable<string> {
  return this.http.get<{ name: string }>(Base_Url + 'api/urls/user').pipe(
      map((res: any) => res.name),
      catchError(() => of('Unknown User'))
    );
  }
}
