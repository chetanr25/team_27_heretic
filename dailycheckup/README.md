# Patient Care Monitoring System

A Streamlit-based application for patient daily checkups and doctor monitoring.

## Features

- User authentication system for doctors and patients
- Daily checkup questionnaire generation based on treatment type
- AI-powered summary of patient responses
- Doctor dashboard to monitor patient reports
- Report download functionality

## Setup Instructions

1. Install required packages:
   ```
   pip install -r requirements.txt
   ```

2. Run the application:
   ```
   cd dailycheckup
   streamlit run app.py
   ```

3. Access the application at http://localhost:8501

## System Requirements

- Python 3.7+
- Internet connection for API access
- NVIDIA NIM API key (provided by default for demo purposes)

## User Guide

### Registration
- Both doctors and patients can register for accounts
- Doctors need to provide specialty and professional email
- Patients need to provide basic information including age

### Patient Workflow
1. Log in as a patient
2. Enter treatment information
3. Answer daily checkup questions
4. Review and download the generated summary

### Doctor Workflow
1. Log in as a doctor
2. View all patient reports in the dashboard
3. Filter reports by patient name, ID, or date
4. Download individual reports

## Data Storage

- Patient reports are stored in the `patient_reports` directory
- User accounts are stored in `data/users.pkl`

## Security Notes

- Passwords are stored as SHA-256 hashes
- API keys should be kept confidential in production environments
