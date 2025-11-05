import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { UrlManagementService } from '../url-management/services/url-management.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css'],
  standalone: true,
  imports: [RouterLink, CommonModule]
})
export class HomeComponent implements OnInit {
  totalUrls: number = 0;
  isLoading: boolean = true;

  constructor(private urlService: UrlManagementService) {}

  ngOnInit(): void {
    this.loadUrlCount();
  }

  private loadUrlCount(): void {
    this.urlService.getUrls().subscribe({
      next: (urls) => {
        this.totalUrls = urls.length;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading URL count:', error);
        this.isLoading = false;
      }
    });
  }
}
