import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { UrlManagementService } from '../services/url-management.service';
import { UrlEntry } from '../models/url-entry.model';
import { Observable } from 'rxjs';

import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-url-list',
  templateUrl: './url-list.component.html',
  styleUrls: ['./url-list.component.css'],
  standalone: true,
  imports: [CommonModule, FormsModule]
})
export class UrlListComponent {
// ...existing imports and @Component remain at the top of the file...
  goHome() {
    this.router.navigate(['/']);
  }
  bannerMessage: string = '';
  bannerType: string = 'info';
  showDeleteModal: boolean = false;
  deleteTarget: UrlEntry | null = null;

  openDeleteModal(entry: UrlEntry) {
    this.deleteTarget = entry;
    this.showDeleteModal = true;
  }

  closeDeleteModal() {
    this.showDeleteModal = false;
    this.deleteTarget = null;
  }

  confirmDelete() {
    if (!this.deleteTarget || !this.deleteTarget.id) return;
    this.urlService.deleteUrl(this.deleteTarget.id).subscribe(() => {
      this.bannerMessage = 'URL deleted successfully!';
      this.bannerType = 'danger';
      this.urlService.getUrls().subscribe(entries => {
        this.allEntries = entries;
        this.filteredEntries = entries;
      });
      setTimeout(() => this.bannerMessage = '', 3000);
      this.closeDeleteModal();
    });
  }
  refresh() {
    this.urlService.getUrls().subscribe(entries => {
      this.allEntries = entries;
      this.filteredEntries = entries;
    });
  }
  urlEntries$: Observable<UrlEntry[]>;
  filteredEntries: UrlEntry[] = [];
  allEntries: UrlEntry[] = [];
  searchTerm = '';
  editingId: string | null = null;
  editShortName: string = '';
  editLongUrl: string = '';
  startEdit(entry: UrlEntry) {
    this.editingId = entry.id ? entry.id.toString() : null;
    if (typeof entry.shortName === 'string') {
      this.editShortName = entry.shortName;
      console.log(entry);
    } else {
      this.editShortName = '';
    }
    this.editLongUrl = entry.longUrl;
  }

  saveEdit(entry: UrlEntry) {
  const updated: UrlEntry = { ...entry, shortName: this.editShortName, longUrl: this.editLongUrl };
    this.urlService.updateUrl(updated).subscribe(result => {
      this.bannerMessage = 'URL updated successfully!';
      this.bannerType = 'success';
      this.urlService.getUrls().subscribe(entries => {
        this.allEntries = entries;
        this.filteredEntries = entries;
      });
      this.editingId = null;
      this.editShortName = '';
      this.editLongUrl = '';
      setTimeout(() => this.bannerMessage = '', 3000);
    });
  }

  cancelEdit() {
    this.editingId = null;
    this.editShortName = '';
    this.editLongUrl = '';
  }

  constructor(private urlService: UrlManagementService, private router: Router) {
    this.urlEntries$ = this.urlService.getUrls();
    this.urlEntries$.subscribe(entries => {
      this.allEntries = entries;
      this.filteredEntries = entries;
    });
  }

  filterAndSort() {
    this.filteredEntries = this.allEntries.filter(e =>
      e.shortName.toLowerCase().includes(this.searchTerm.toLowerCase())
    );
  }

  search() {
    if (this.searchTerm.trim() === '') {
      // If search is empty, show all
      this.urlService.getUrls().subscribe(entries => {
        this.filteredEntries = entries;
      });
    } else {
      this.urlService.searchShortName(this.searchTerm).subscribe(entries => {
        this.filteredEntries = entries;
        this.bannerMessage = 'Search completed.';
        this.bannerType = 'info';
        setTimeout(() => this.bannerMessage = '', 2000);
      });
    }
  }

  // Edit and delete methods removed
}
