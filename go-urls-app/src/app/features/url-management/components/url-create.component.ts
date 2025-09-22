import { Component, Output, EventEmitter } from '@angular/core';
import { Router } from '@angular/router';
import { UrlManagementService } from '../services/url-management.service';
import { UrlEntry } from '../models/url-entry.model';
import { Guid } from 'guid-typescript';


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
  @Output() urlAdded = new EventEmitter<void>();
  shortName = '';
  longUrl = '';

  constructor(private urlService: UrlManagementService, private router: Router) {}
  goHome() {
    this.router.navigate(['/']);
  }
  ngOnInit() {
    this.loadAll();
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
      this.urlService.addUrl(entry).subscribe(() => {
        this.bannerMessage = 'URL created successfully!';
        this.bannerType = 'success';
        this.urlAdded.emit();
        this.shortName = '';
        this.longUrl = '';
        this.loadAll();
        setTimeout(() => this.bannerMessage = '', 3000);
      });
    });
  }
}
