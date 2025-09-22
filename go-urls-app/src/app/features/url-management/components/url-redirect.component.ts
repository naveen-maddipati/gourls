import { Component } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
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

  constructor(private urlService: UrlManagementService, private route: ActivatedRoute) {
    this.route.params.subscribe(params => {
      const shortName = params['shortName'];
      console.log('UrlRedirectComponent: shortName', shortName);
      if (shortName) {
        this.redirect(shortName);
      }
    });
  }

  redirect(shortName: string) {
    this.urlService.getUrls().subscribe(entries => {
      const found = entries.find(e => e.shortName === shortName);
      if (found) {
        window.location.href = found.longUrl;
      } else {
        // Show home page and message
        this.redirectUrl = null;
        // Use Angular router to navigate to home and pass message
        window.location.href = '/?availableShortName=' + encodeURIComponent(shortName);
        console.log('UrlRedirectComponent: unknown shortName, redirecting to home with banner', shortName);
      }
    });
  }
}
