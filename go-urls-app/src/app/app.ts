import { Component, signal, OnInit, inject } from '@angular/core';
import { NgClass, CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { HttpClientModule } from '@angular/common/http';
import { UserService } from './core/services/user.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, NgClass, CommonModule, HttpClientModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {
  protected readonly title = signal('go-urls-app');
  private userService = inject(UserService);
  
  bannerMessage = '';
  bannerType: string = 'info';
  searchTerm: string = '';
  currentUser: string = 'Loading...';

  ngOnInit() {
    // Load current user
    this.userService.getUserName().subscribe({
      next: (username) => {
        this.currentUser = username || 'Unknown User';
      },
      error: () => {
        this.currentUser = 'Unknown User';
      }
    });

    // Handle URL parameters for banner messages
    const params = new URLSearchParams(window.location.search);
    const availableShortName = params.get('availableShortName');
    console.log('ngOnInit: availableShortName', availableShortName);
    if (availableShortName) {
      this.bannerMessage = `Short name '${availableShortName}' is available to use!`;
      this.bannerType = 'info';
      window.history.replaceState({}, '', window.location.pathname);
    }
  }
}
