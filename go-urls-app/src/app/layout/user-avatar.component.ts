import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserService } from '../core/services/user.service';

@Component({
  selector: 'app-user-avatar',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="user-avatar-container">
      <img class="avatar" src="/assets/avatar-default.png" alt="User Avatar" />
      <span class="username">{{ userName }}</span>
    </div>
  `,
  styleUrls: ['./user-avatar.component.css']
})
export class UserAvatarComponent implements OnInit {
  userName = '';

  constructor(private userService: UserService) {}

  ngOnInit() {
    this.userService.getUserName().subscribe(name => {
      this.userName = name;
    });
  }
}
