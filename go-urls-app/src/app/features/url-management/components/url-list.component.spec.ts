import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UrlListComponent } from './url-list.component';
import { UrlManagementService } from '../services/url-management.service';
import { FormsModule } from '@angular/forms';
import { of } from 'rxjs';
import { Guid } from 'guid-typescript';

describe('UrlListComponent', () => {
  let component: UrlListComponent;
  let fixture: ComponentFixture<UrlListComponent>;
  let service: UrlManagementService;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [UrlListComponent],
      imports: [FormsModule],
      providers: [UrlManagementService]
    }).compileComponents();

    fixture = TestBed.createComponent(UrlListComponent);
    component = fixture.componentInstance;
    service = TestBed.inject(UrlManagementService);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should filter and sort entries', () => {
  service.addUrl({ id: Guid.create(), shortName: 'abc', longUrl: 'url'}).subscribe();
  service.addUrl({ id: Guid.create(), shortName: 'xyz', longUrl: 'url'}).subscribe();
    component.searchTerm = 'a';
  // component.urlEntries$ = service.getUrlEntries(); // Removed: getUrlEntries does not exist on UrlManagementService
    component.urlEntries$.subscribe(entries => {
      component.allEntries = entries;
      component.filterAndSort();
      expect(component.filteredEntries.length).toBe(1);
    });
  });
});