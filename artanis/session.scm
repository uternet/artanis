;;  -*-  indent-tabs-mode:nil; coding: utf-8 -*-
;;  Copyright (C) 2013
;;      "Mu Lei" known as "NalaGinrut" <NalaGinrut@gmail.com>
;;  Artanis is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  Artanis is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

(define-module (artanis session)
  #:use-module (artanis utils)
  #:use-module (artanis artanis)
  #:use-module (srfi srfi-9)
  #:use-module (web request)
  #:export (session-set! session-ref session-spawn session-destory 
            session-restore has-auth?))

;; TODO: now we don't have swap algorithm yet, which means all the sessions
;;       are memcached.
;; memcached session
(define *sessions-table* (make-hash-table))

(define (mem:get-session sid)
  (hash-ref *sessions-table* sid))

(define (mem:store-session sid session)
  (hash-set! *sessions-table* sid session))

(define (mem:delete-session sid)
  (hash-remove! *sessions-table* sid))
;; --- end memcached session

(define (session-set! session key val)
  (hash-set! session key val))

(define (session-ref session key)
  (hash-ref session key))

(define (make-session . args)
  (let ((ht (make-hash-table)))
    (for-each (lambda (e)
                (hash-set! ht (car e) (cdr e)))
              args)
    ht))

(define (get-new-id)
  (let ((now (object->string (current-time)))
        (pid (object->string (getpid)))
        (rand (object->string (unsafe-random)))
        (me "nalaginrut"))
    (string->md5 (string-append now pid rand me))))
    
(define (get-session sid)
  (and (mem:get-session sid)
       (get-session-file sid)))

(define (session-expired? session)
  (let ((now (current-time))
        (expires (expires->time-utc (session-ref session "expires"))))
    (> now expires)))

(define (session-destory sid)
  (mem:delete-session sid) ; delete from memcached if exists
  (delete-session-file sid))

(define (session-restore sid)
  (let ((session (get-session sid)))
    (cond
     ((or (not session) (session-expired? session))
      (session-destory sid)
      #f) ; expired then return #f
     (else session))))
    
(define (new-session rc)
  (let ((expires (params rc "session_expires"))
        (domain (params rc "sessioin_domain"))
        (secure (params rc "session_secure"))
        (path (rc-path rc)))
    (make-session `(("expires" . ,expires)
                    ("domain"  . ,domain)
                    ("secure"  . ,secure)
                    ("path"    . ,path)))))

(define (session-spawn rc)
  (let* ((sid (get-new-id))
         (session (or (and sid (session-restore sid)) (new-session rc))))
    (values sid 
            (store-session sid session))))

(define* (has-auth? rc #:key (key "sid"))
  (let ((sid (params rc key)))
    (and sid (get-session sid))))

(define (session->alist session)
  (hash-map->list list session))

;; return filename if it exists, or #f
(define (get-session-file sid)
  (let ((f (format #f "~a/~a.session" *session-path* sid)))
    (and (file-exists? f) f)))

(define (load-session-from-file sid)
  (let ((f (get-cookie-file sid)))
    (and f ; if cookie file exists
         (call-with-input-file sid
           (lambda (port)
             (make-session (read port)))))))

(define (save-session-to-file sid)
  (let ((s (session->alist (get-session sid)))
        (f (get-session-file sid)))
    ;; if file exists, it'll be removed then create a new one
    (and f (delete-file f)) 
    (call-with-output-file f
      (lambda (port)
        (write s f)))))

(define (delete-session-file sid)
  (let ((f (get-session-file sid)))
    (and f (delete-file f))))
