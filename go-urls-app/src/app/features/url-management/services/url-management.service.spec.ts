import { UrlManagementService } from './url-management.service';
import { UrlEntry } from '../models/url-entry.model';
import { TestBed } from '@angular/core/testing';
import { Guid } from 'guid-typescript';
import { HttpClientTestingModule } from '@angular/common/http/testing';

describe('UrlManagementService', () => {
  let service: UrlManagementService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UrlManagementService]
    });
    service = TestBed.inject(UrlManagementService);
  });

  it('should add a new url entry', (done) => {
  const entry: UrlEntry = {
    id: Guid.create(),
    shortName: 'test',
    longUrl: 'http://example.com'
  };
  service.addUrl(entry).subscribe(result => {
    expect(result.shortName).toBe('test');
    service.getUrls().subscribe(urls => {
      expect(urls.length).toBeGreaterThan(0);
      done();
    });
  });
  });

  it('should update an entry', (done) => {
    const entry: UrlEntry = {
      id: Guid.create(),
      shortName: 'test',
      longUrl: 'http://example.com'
    };
    service.addUrl(entry).subscribe(added => {
      added.shortName = 'updated';
      service.updateUrl(added).subscribe(updated => {
        expect(updated.shortName).toBe('updated');
        done();
      });
    });
  });

  it('should delete an entry', (done) => {
    const entry: UrlEntry = {
      id: Guid.create(),
      shortName: 'test',
      longUrl: 'http://example.com'
    };
    service.addUrl(entry).subscribe(added => {
      service.deleteUrl(added.id!).subscribe(result => {
        expect(result).toBeTruthy();
        service.getUrls().subscribe(urls => {
          done();
        });
      });
    });
  });

  it('should search for an entry', (done) => {
    const entry: UrlEntry = {
      id: Guid.create(),
      shortName: 'searchme',
      longUrl: 'http://example.com'
    };
    service.addUrl(entry).subscribe(() => {
      service.searchShortName('searchme').subscribe(results => {
        expect(results.length).toBeGreaterThan(0);
        expect(results[0].shortName).toBe('searchme');
        done();
      });
    });
  });
});