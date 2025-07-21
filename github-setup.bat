@echo off
setlocal enabledelayedexpansion

echo ========================================
echo GitHub Repository Auto-Setup Script
echo ========================================
echo.

:: Check if GitHub CLI is installed
gh --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: GitHub CLI is not installed or not in PATH
    echo Please install GitHub CLI from: https://cli.github.com/
    pause
    exit /b 1
)

:: Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not in PATH
    echo Please install Git from: https://git-scm.com/
    pause
    exit /b 1
)

:: Get repository name
set /p REPO_NAME="Enter repository name: "
if "%REPO_NAME%"=="" (
    echo ERROR: Repository name cannot be empty
    pause
    exit /b 1
)

:: Get project directory path
set /p PROJECT_DIR="Enter full path to project directory: "
if "%PROJECT_DIR%"=="" (
    echo ERROR: Project directory path cannot be empty
    pause
    exit /b 1
)

:: Check if project directory exists
if not exist "%PROJECT_DIR%" (
    echo ERROR: Project directory does not exist: %PROJECT_DIR%
    pause
    exit /b 1
)

:: Get repository description
set /p REPO_DESC="Enter repository description (optional): "

:: Ask for repository visibility
echo.
echo Repository visibility:
echo 1. Public
echo 2. Private
set /p VISIBILITY_CHOICE="Choose visibility (1 or 2): "

if "%VISIBILITY_CHOICE%"=="2" (
    set VISIBILITY=--private
) else (
    set VISIBILITY=--public
)

:: Get project type for README template
echo.
echo Select project type for README template:
echo 1. General/Other
echo 2. Web Application
echo 3. Python Project
echo 4. Node.js Project
echo 5. Java Project
set /p PROJECT_TYPE="Choose project type (1-5): "

echo.
echo ========================================
echo Creating GitHub repository...
echo ========================================

:: Create GitHub repository
if "%REPO_DESC%"=="" (
    gh repo create %REPO_NAME% %VISIBILITY% --clone
) else (
    gh repo create %REPO_NAME% %VISIBILITY% --description "%REPO_DESC%" --clone
)

if errorlevel 1 (
    echo ERROR: Failed to create GitHub repository
    pause
    exit /b 1
)

echo Repository created successfully!

:: Navigate to the cloned repository (create a temporary subdirectory to avoid conflicts)
set "TEMP_REPO_DIR=%cd%\temp_%REPO_NAME%"
if exist "%TEMP_REPO_DIR%" rmdir /s /q "%TEMP_REPO_DIR%"
mkdir "%TEMP_REPO_DIR%"
cd "%TEMP_REPO_DIR%"

:: Clone the repository into current temp directory
gh repo clone %REPO_NAME% .
if errorlevel 1 (
    echo ERROR: Failed to clone the repository
    cd "%PROJECT_DIR%"
    rmdir /s /q "%TEMP_REPO_DIR%" 2>nul
    pause
    exit /b 1
)

echo.
echo ========================================
echo Copying project files...
echo ========================================

:: Create temporary batch file to exclude github-setup.bat
echo @echo off > temp_copy.bat
echo for /f "delims=" %%%%i in ('dir /b /a-d "%PROJECT_DIR%"') do ( >> temp_copy.bat
echo     if /i not "%%%%i"=="github-setup.bat" if /i not "%%%%i"=="temp_copy.bat" ( >> temp_copy.bat
echo         copy "%PROJECT_DIR%\%%%%i" "." ^>nul >> temp_copy.bat
echo     ) >> temp_copy.bat
echo ) >> temp_copy.bat

:: Copy files (excluding github-setup.bat and temp files)
for %%f in ("%PROJECT_DIR%\*") do (
    if /i not "%%~nxf"=="github-setup.bat" (
        if /i not "%%~nxf"=="temp_copy.bat" (
            copy "%%f" "." >nul 2>&1
        )
    )
)

:: Copy directories recursively (excluding any directory that might contain the script)
for /d %%d in ("%PROJECT_DIR%\*") do (
    xcopy "%%d" "%%~nxd\" /E /H /Y /I >nul 2>&1
)

:: Clean up temporary file
if exist temp_copy.bat del temp_copy.bat

echo Project files copied successfully (github-setup.bat excluded)!

echo.
echo ========================================
echo Creating README.md...
echo ========================================

:: Create README.md based on project type
if "%PROJECT_TYPE%"=="2" (
    call :create_web_readme
) else if "%PROJECT_TYPE%"=="3" (
    call :create_python_readme
) else if "%PROJECT_TYPE%"=="4" (
    call :create_nodejs_readme
) else if "%PROJECT_TYPE%"=="5" (
    call :create_java_readme
) else (
    call :create_general_readme
)

echo README.md created successfully!

echo.
echo ========================================
echo Initializing git and making first commit...
echo ========================================

:: Add all files to git (make sure we exclude github-setup.bat if it somehow got copied)
if exist github-setup.bat del github-setup.bat
git add .
if errorlevel 1 (
    echo ERROR: Failed to add files to git
    cd "%PROJECT_DIR%"
    rmdir /s /q "%TEMP_REPO_DIR%" 2>nul
    pause
    exit /b 1
)

:: Make initial commit
git commit -m "Initial commit: Add project files and README"
if errorlevel 1 (
    echo ERROR: Failed to make initial commit
    cd "%PROJECT_DIR%"
    rmdir /s /q "%TEMP_REPO_DIR%" 2>nul
    pause
    exit /b 1
)

:: Push to main branch (GitHub's default)
git push -u origin main
if errorlevel 1 (
    echo ERROR: Failed to push to GitHub
    cd "%PROJECT_DIR%"
    rmdir /s /q "%TEMP_REPO_DIR%" 2>nul
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! Repository setup complete!
echo ========================================
echo Repository URL: https://github.com/$(gh api user --jq .login)/%REPO_NAME%
echo Temp directory used: %TEMP_REPO_DIR%
echo Original project directory: %PROJECT_DIR%
echo.
echo Note: You can safely delete the temp directory after confirming everything is working.
echo.

:: Return to original project directory
cd "%PROJECT_DIR%"

pause
exit /b 0

:: README templates
:create_general_readme
(
echo # %REPO_NAME%
echo.
if not "%REPO_DESC%"=="" echo %REPO_DESC%
if not "%REPO_DESC%"=="" echo.
echo ## Description
echo.
echo Add a brief description of your project here.
echo.
echo ## Installation
echo.
echo ```bash
echo # Add installation instructions here
echo ```
echo.
echo ## Usage
echo.
echo ```bash
echo # Add usage examples here
echo ```
echo.
echo ## Contributing
echo.
echo Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
echo.
echo ## License
echo.
echo [MIT](https://choosealicense.com/licenses/mit/^)
) > README.md
goto :eof

:create_web_readme
(
echo # %REPO_NAME%
echo.
if not "%REPO_DESC%"=="" echo %REPO_DESC%
if not "%REPO_DESC%"=="" echo.
echo ## Features
echo.
echo - Feature 1
echo - Feature 2
echo - Feature 3
echo.
echo ## Technologies Used
echo.
echo - HTML5
echo - CSS3
echo - JavaScript
echo.
echo ## Installation
echo.
echo 1. Clone the repository:
echo    ```bash
echo    git clone https://github.com/yourusername/%REPO_NAME%.git
echo    ```
echo.
echo 2. Navigate to the project directory:
echo    ```bash
echo    cd %REPO_NAME%
echo    ```
echo.
echo 3. Open `index.html` in your browser or use a local server.
echo.
echo ## Usage
echo.
echo Describe how to use your web application here.
echo.
echo ## Contributing
echo.
echo 1. Fork the repository
echo 2. Create your feature branch (`git checkout -b feature/AmazingFeature`^)
echo 3. Commit your changes (`git commit -m 'Add some AmazingFeature'`^)
echo 4. Push to the branch (`git push origin feature/AmazingFeature`^)
echo 5. Open a Pull Request
echo.
echo ## License
echo.
echo This project is licensed under the MIT License - see the [LICENSE](LICENSE^) file for details.
) > README.md
goto :eof

:create_python_readme
(
echo # %REPO_NAME%
echo.
if not "%REPO_DESC%"=="" echo %REPO_DESC%
if not "%REPO_DESC%"=="" echo.
echo ## Requirements
echo.
echo - Python 3.7+
echo - pip
echo.
echo ## Installation
echo.
echo 1. Clone the repository:
echo    ```bash
echo    git clone https://github.com/yourusername/%REPO_NAME%.git
echo    cd %REPO_NAME%
echo    ```
echo.
echo 2. Create a virtual environment:
echo    ```bash
echo    python -m venv venv
echo    source venv/bin/activate  # On Windows: venv\Scripts\activate
echo    ```
echo.
echo 3. Install dependencies:
echo    ```bash
echo    pip install -r requirements.txt
echo    ```
echo.
echo ## Usage
echo.
echo ```bash
echo python main.py
echo ```
echo.
echo ## Project Structure
echo.
echo ```
echo %REPO_NAME%/
echo ├── main.py
echo ├── requirements.txt
echo ├── README.md
echo └── src/
echo     └── ...
echo ```
echo.
echo ## Contributing
echo.
echo 1. Fork the repository
echo 2. Create your feature branch (`git checkout -b feature/AmazingFeature`^)
echo 3. Commit your changes (`git commit -m 'Add some AmazingFeature'`^)
echo 4. Push to the branch (`git push origin feature/AmazingFeature`^)
echo 5. Open a Pull Request
echo.
echo ## License
echo.
echo This project is licensed under the MIT License - see the [LICENSE](LICENSE^) file for details.
) > README.md
goto :eof

:create_nodejs_readme
(
echo # %REPO_NAME%
echo.
if not "%REPO_DESC%"=="" echo %REPO_DESC%
if not "%REPO_DESC%"=="" echo.
echo ## Prerequisites
echo.
echo - Node.js (v14 or higher^)
echo - npm or yarn
echo.
echo ## Installation
echo.
echo 1. Clone the repository:
echo    ```bash
echo    git clone https://github.com/yourusername/%REPO_NAME%.git
echo    cd %REPO_NAME%
echo    ```
echo.
echo 2. Install dependencies:
echo    ```bash
echo    npm install
echo    # or
echo    yarn install
echo    ```
echo.
echo ## Usage
echo.
echo ### Development
echo ```bash
echo npm run dev
echo # or
echo yarn dev
echo ```
echo.
echo ### Production
echo ```bash
echo npm start
echo # or
echo yarn start
echo ```
echo.
echo ## Scripts
echo.
echo - `npm run dev` - Start development server
echo - `npm run build` - Build for production
echo - `npm test` - Run tests
echo - `npm start` - Start production server
echo.
echo ## Project Structure
echo.
echo ```
echo %REPO_NAME%/
echo ├── package.json
echo ├── README.md
echo ├── src/
echo │   ├── index.js
echo │   └── ...
echo └── tests/
echo     └── ...
echo ```
echo.
echo ## Contributing
echo.
echo 1. Fork the repository
echo 2. Create your feature branch (`git checkout -b feature/AmazingFeature`^)
echo 3. Commit your changes (`git commit -m 'Add some AmazingFeature'`^)
echo 4. Push to the branch (`git push origin feature/AmazingFeature`^)
echo 5. Open a Pull Request
echo.
echo ## License
echo.
echo This project is licensed under the MIT License - see the [LICENSE](LICENSE^) file for details.
) > README.md
goto :eof

:create_java_readme
(
echo # %REPO_NAME%
echo.
if not "%REPO_DESC%"=="" echo %REPO_DESC%
if not "%REPO_DESC%"=="" echo.
echo ## Prerequisites
echo.
echo - Java 8 or higher
echo - Maven or Gradle
echo.
echo ## Installation
echo.
echo 1. Clone the repository:
echo    ```bash
echo    git clone https://github.com/yourusername/%REPO_NAME%.git
echo    cd %REPO_NAME%
echo    ```
echo.
echo 2. Build the project:
echo    ```bash
echo    # Using Maven
echo    mvn clean install
echo    
echo    # Using Gradle
echo    gradle build
echo    ```
echo.
echo ## Usage
echo.
echo ```bash
echo # Using Maven
echo mvn exec:java
echo 
echo # Using Gradle
echo gradle run
echo 
echo # Using compiled JAR
echo java -jar target/%REPO_NAME%-1.0.jar
echo ```
echo.
echo ## Project Structure
echo.
echo ```
echo %REPO_NAME%/
echo ├── pom.xml ^(or build.gradle^)
echo ├── README.md
echo ├── src/
echo │   ├── main/
echo │   │   └── java/
echo │   └── test/
echo │       └── java/
echo └── target/ ^(or build/^)
echo ```
echo.
echo ## Contributing
echo.
echo 1. Fork the repository
echo 2. Create your feature branch (`git checkout -b feature/AmazingFeature`^)
echo 3. Commit your changes (`git commit -m 'Add some AmazingFeature'`^)
echo 4. Push to the branch (`git push origin feature/AmazingFeature`^)
echo 5. Open a Pull Request
echo.
echo ## License
echo.
echo This project is licensed under the MIT License - see the [LICENSE](LICENSE^) file for details.
) > README.md
goto :eof