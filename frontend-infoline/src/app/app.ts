import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('Hello World !');
  protected readonly isOnline = signal(true);
  protected readonly currentDate = new Date();
  
  protected readonly appInfo = {
    name: 'InfoLine Frontend',
    version: '1.0.0',
    framework: 'Angular 19'
  };
}