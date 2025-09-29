import { Component, signal } from '@angular/core';
import { NgClass, CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, NgClass, CommonModule, HttpClientModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('go-urls-app');
  bannerMessage = '';
  bannerType: string = 'info';
  searchTerm: string = '';
  ngOnInit() {
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
