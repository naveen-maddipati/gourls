import { Component, signal } from '@angular/core';
import { NgClass } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { HttpClientModule } from '@angular/common/http';
import { UserAvatarComponent } from './layout/user-avatar.component';
import { UrlCreateComponent } from './features/url-management/components/url-create.component';
import { UrlListComponent } from './features/url-management/components/url-list.component';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, NgClass, HttpClientModule, UserAvatarComponent, UrlCreateComponent, UrlListComponent],
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
