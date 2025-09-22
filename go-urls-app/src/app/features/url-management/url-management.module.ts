import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UrlListComponent } from './components/url-list.component';
import { UrlCreateComponent } from './components/url-create.component';
import { UrlRedirectComponent } from './components/url-redirect.component';

@NgModule({
  imports: [CommonModule, FormsModule, UrlListComponent, UrlCreateComponent, UrlRedirectComponent],
  exports: [UrlListComponent, UrlCreateComponent, UrlRedirectComponent]
})
export class UrlManagementModule {}
