import { Routes } from '@angular/router';

import { UrlRedirectComponent } from './features/url-management/components/url-redirect.component';
import { HomeComponent } from './features/home/home.component';
import { UrlListComponent } from './features/url-management/components/url-list.component';
import { UrlCreateComponent } from './features/url-management/components/url-create.component';

export const routes: Routes = [
	{ path: '', component: HomeComponent },
	{ path: 'search', component: UrlListComponent },
	{ path: 'create', component: UrlCreateComponent },
	{ path: ':shortName', component: UrlRedirectComponent }
];
