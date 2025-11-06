import { Component } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { UrlManagementService } from '../services/url-management.service';
import { UrlEntry } from '../models/url-entry.model';

import { CommonModule } from '@angular/common';
@Component({
  selector: 'app-url-redirect',
  template: `<div *ngIf="redirectUrl">Redirecting to: {{ redirectUrl }}</div>`,
  standalone: true,
  imports: [CommonModule]
})
export class UrlRedirectComponent {
  redirectUrl: string | null = null;

  constructor(
    private urlService: UrlManagementService, 
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.route.params.subscribe(params => {
      const shortName = params['shortName'];
      console.log('UrlRedirectComponent: shortName', shortName);
      if (shortName) {
        this.redirect(shortName);
      }
    });
  }

  redirect(shortName: string) {
    this.urlService.getByShortName(shortName).subscribe({
      next: (entry) => {
        console.log('Found URL entry:', entry);
        window.location.href = entry.longUrl;
      },
      error: (error) => {
        console.log('URL not found:', shortName, error);
        // Redirect directly to create page with the shortName pre-filled
        this.router.navigate(['/create'], { 
          queryParams: { shortName: shortName } 
        });
        console.log('UrlRedirectComponent: unknown shortName, redirecting to create page', shortName);
      }
    });
  }
}
