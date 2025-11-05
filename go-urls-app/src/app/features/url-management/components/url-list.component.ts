import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { UrlManagementService } from '../services/url-management.service';
import { UrlEntry } from '../models/url-entry.model';
import { Observable } from 'rxjs';
import { Go_Domain } from '../../../core/constants';

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
  Math = Math; // Make Math available in template
  
  goHome() {
    this.router.navigate(['/']);
  }
  bannerMessage: string = '';
  bannerType: string = 'info';
  showDeleteModal: boolean = false;
  goDomain = Go_Domain; // Make Go_Domain available in template
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
        this.updatePagination();
      });
      setTimeout(() => this.bannerMessage = '', 3000);
      this.closeDeleteModal();
    });
  }
  refresh() {
    this.urlService.getUrls().subscribe(entries => {
      this.allEntries = entries;
      this.filteredEntries = entries;
      this.updatePagination();
    });
  }
  urlEntries$: Observable<UrlEntry[]>;
  filteredEntries: UrlEntry[] = [];
  allEntries: UrlEntry[] = [];
  searchTerm = '';
  editingId: string | null = null;
  editShortName: string = '';
  editLongUrl: string = '';

  // Pagination properties
  currentPage: number = 1;
  itemsPerPage: number = 10;
  totalItems: number = 0;
  totalPages: number = 0;
  paginatedEntries: UrlEntry[] = [];
  pageNumbers: number[] = [];

  // Pagination methods
  updatePagination() {
    this.totalItems = this.filteredEntries.length;
    this.totalPages = Math.ceil(this.totalItems / this.itemsPerPage);
    this.currentPage = Math.min(this.currentPage, Math.max(1, this.totalPages));
    
    const startIndex = (this.currentPage - 1) * this.itemsPerPage;
    const endIndex = startIndex + this.itemsPerPage;
    this.paginatedEntries = this.filteredEntries.slice(startIndex, endIndex);
    
    this.updatePageNumbers();
  }

  updatePageNumbers() {
    this.pageNumbers = [];
    const maxPageButtons = 5;
    let startPage = Math.max(1, this.currentPage - Math.floor(maxPageButtons / 2));
    let endPage = Math.min(this.totalPages, startPage + maxPageButtons - 1);
    
    // Adjust startPage if we're near the end
    if (endPage - startPage + 1 < maxPageButtons) {
      startPage = Math.max(1, endPage - maxPageButtons + 1);
    }
    
    for (let i = startPage; i <= endPage; i++) {
      this.pageNumbers.push(i);
    }
  }

  goToPage(page: number) {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
      this.updatePagination();
    }
  }

  previousPage() {
    this.goToPage(this.currentPage - 1);
  }

  nextPage() {
    this.goToPage(this.currentPage + 1);
  }

  changeItemsPerPage(newSize: number) {
    this.itemsPerPage = newSize;
    this.currentPage = 1;
    this.updatePagination();
  }
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
        this.updatePagination();
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
      this.updatePagination();
    });
  }

  filterAndSort() {
    this.filteredEntries = this.allEntries.filter(e =>
      e.shortName.toLowerCase().includes(this.searchTerm.toLowerCase())
    );
    this.currentPage = 1; // Reset to first page when filtering
    this.updatePagination();
  }

  search() {
    if (this.searchTerm.trim() === '') {
      // If search is empty, show all
      this.urlService.getUrls().subscribe(entries => {
        this.filteredEntries = entries;
        this.currentPage = 1;
        this.updatePagination();
      });
    } else {
      this.urlService.searchShortName(this.searchTerm).subscribe(entries => {
        this.filteredEntries = entries;
        this.currentPage = 1;
        this.updatePagination();
        this.bannerMessage = 'Search completed.';
        this.bannerType = 'info';
        setTimeout(() => this.bannerMessage = '', 2000);
      });
    }
  }

  // Edit and delete methods removed
}
