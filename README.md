# project-lab-2025

A modern shopping list application built with Flutter and FastAPI that helps households manage their shopping with AI-powered predictions and real-time price comparisons.

## Features

**Household Management**
Create and manage households with multiple members. Invite family members and collaborate on shopping lists with role-based permissions.

**Smart Shopping Lists**
Create organized shopping lists for your household. Add items from a comprehensive catalog with automatic price and manufacturer information. Mark completed lists to track your shopping history.

**AI-Powered Predictions**
Get intelligent item suggestions based on your purchase history. The application uses machine learning algorithm to learn your shopping patterns and suggest items you're likely to need.

**Price Comparison**
Compare prices across multiple store chains in real-time. Use GPS location to find nearby stores and get the best deals for your shopping list.

**Purchase History**
Track your completed shopping trips and analyze spending patterns. Restore previous shopping lists or individual items with one tap.

**Store Integration**
Access real-time price data from major Israeli retailers with daily updates from government sources.

## Technology

The frontend is built with Flutter for cross-platform mobile support. The backend uses FastAPI with PostgreSQL for data storage and includes background tasks for automated price updates and machine learning model training.

## Quick Start

Start the backend services:
```bash
docker-compose up -d
```

Install Flutter dependencies and run the mobile app:
```bash
cd frondend
flutter pub get
flutter run
```

The database will be automatically initialized when the backend starts.

## API Overview

The application provides RESTful APIs for authentication, household management, shopping list operations, AI predictions, and price comparisons. All endpoints require JWT authentication except for registration and login.

## Machine Learning

The application uses association rule mining with the Apriori algorithm to generate shopping predictions. The system analyzes completed shopping lists to find patterns and create intelligent suggestions. Rules are automatically updated through background tasks that run daily.

## Data Sources

Price data comes from the Israeli government's published prices database, which includes information from major retail chains. The system automatically downloads and processes this data daily to maintain current pricing information.

## License

This project is licensed under the MIT License.