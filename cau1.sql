CREATE DATABASE RikkeiClinicDB;
USE RikkeiClinicDB;

CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    patient_type varchar(20),
	total_cost decimal(18, 2)
);

CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Completed', 'Cancelled'
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

INSERT INTO Patients (patient_name, patient_type, total_cost) 
VALUES
	('Dansuraito', 'BHYT', 1000),
	('Thoái Văn', 'VIP', 3060),
	('Suy Cong', 'THUONG', 6300),
	('Dick Grayson', 'VIP', 6900);

INSERT INTO Appointments (appointment_id, patient_id, appointment_date, status) 
VALUES
	(104, 1, '2026-06-10 08:30:00', 'Pending'),
	(105, 2, '2026-05-01 09:00:00', 'Completed'),
	(106, 3, '2026-05-02 10:00:00', 'Cancelled');

-- code gốc
DELIMITER //

CREATE TRIGGER PreventPastAppointments
BEFORE UPDATE ON Appointments
FOR EACH ROW
BEGIN
    -- Lỗi logic: Đang lấy ngày cũ ra so sánh với hiện tại thay vì kiểm tra ngày mới
    IF OLD.appointment_date < NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không thể đặt lịch khám vào thời điểm trong quá khứ!';
    END IF;
END //

DELIMITER ;

-- Phần A
-- test lỗi
update Appointments
set appointment_date = '2025-01-11'
where appointment_id = 104;
-- sau khi chạy lệnh, tb: 17:17:58	update Appointments set appointment_date = '2025-01-11' where appointment_id = 104	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec
-- nghĩa là hệ thống vẫn chấp nhận sự thay đổi

-- Lỗi nằm ở vc khai OLD.appointment_date và NEW.appointment_date
-- old lấy liệu cũ trc update còn new lấy dữ liệu mới dùng để update, viết OLD.appointment_date nghĩa là lấy dữ liệu ngày tháng cũ chứ ko phải lấy dữ liệu mới nhập vào nghĩa là đang ktra ngày tháng cũ đã có trc đó rùi thành ra bị sai

-- sửa
drop trigger if exists  PreventPastAppointments;

DELIMITER //

CREATE TRIGGER PreventPastAppointments
BEFORE UPDATE ON Appointments
FOR EACH ROW
BEGIN
    IF New.appointment_date < NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Không thể đặt lịch khám vào thời điểm trong quá khứ!';
    END IF;
END //

DELIMITER ;

update Appointments
set appointment_date = '2025-10-11'
where appointment_id = 104;
-- sau khi chạy lệnh tb ở dưới: 18:13:56 update Appointments set appointment_date = '2025-10-11' where appointment_id = 104	Error Code: 1644. Lỗi: Không thể đặt lịch khám vào thời điểm trong quá khứ!	0.000 sec
