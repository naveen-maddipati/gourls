import { Component, Output, EventEmitter } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { UrlManagementService } from '../services/url-management.service';
import { UrlEntry } from '../models/url-entry.model';
import { Guid } from 'guid-typescript';
import { Go_Domain } from '../../../core/constants';

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
@Component({
  selector: 'app-url-create',
  templateUrl: './url-create.component.html',
  styleUrls: ['./url-create.component.css'],
  standalone: true,
  imports: [CommonModule, FormsModule]
})
export class UrlCreateComponent {
  bannerMessage: string = '';
  bannerType: string = 'success';
  allEntries: UrlEntry[] = [];
  goDomain = Go_Domain; // Make Go_Domain available in template
  @Output() urlAdded = new EventEmitter<void>();
  shortName = '';
  longUrl = '';

  constructor(private urlService: UrlManagementService, private router: Router, private route: ActivatedRoute) {}
  goHome() {
    this.router.navigate(['/']);
  }
  ngOnInit() {
    this.loadAll();
    
    // Check for query parameters when redirected from non-existent shortname
    this.route.queryParams.subscribe(params => {
      if (params['shortName'] && params['available'] === 'true') {
        this.shortName = params['shortName'];
        this.bannerMessage = `'${params['shortName']}' is available! Enter a URL below to create this short link.`;
        this.bannerType = 'info';
        setTimeout(() => this.bannerMessage = '', 6000);
      }
    });
  }

  loadAll() {
    this.urlService.getUrls().subscribe(entries => {
      this.allEntries = entries;
    });
  }

  addUrl() {
    // Check uniqueness from DB via API
    this.urlService.searchShortName(this.shortName.trim()).subscribe(entries => {
      const exists = entries.some(e => e.shortName.trim().toLowerCase() === this.shortName.trim().toLowerCase());
      if (exists) {
        this.bannerMessage = `Short name '${this.shortName}' is already taken. Please choose a different one.`;
        this.bannerType = 'danger';
        setTimeout(() => this.bannerMessage = '', 4000);
        return;
      }
      const entry: UrlEntry = {
        shortName: this.shortName,
        longUrl: this.longUrl
      };
      this.urlService.addUrl(entry).subscribe({
        next: () => {
          this.bannerMessage = 'URL created successfully!';
          this.bannerType = 'success';
          this.urlAdded.emit();
          this.shortName = '';
          this.longUrl = '';
          this.loadAll();
          setTimeout(() => this.bannerMessage = '', 3000);
        },
        error: (error) => {
          if (error.status === 400 && error.error?.error === 'Reserved word') {
            this.bannerMessage = `'${this.shortName}' is a reserved word and cannot be used as a short URL.`;
            this.bannerType = 'danger';
          } else if (error.status === 400 && error.error?.error === 'Duplicate') {
            this.bannerMessage = `Short name '${this.shortName}' is already taken. Please choose a different one.`;
            this.bannerType = 'danger';
          } else {
            this.bannerMessage = 'An error occurred while creating the URL. Please try again.';
            this.bannerType = 'danger';
          }
          setTimeout(() => this.bannerMessage = '', 4000);
        }
      });
    });
  }
}
