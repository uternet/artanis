;;  -*-  indent-tabs-mode:nil; coding: utf-8 -*-
;;  Copyright (C) 2014
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

;; -----------------------------------------------------------------------
;; This is where all the global vars should be put.
;; Include global config table, and green-thread working queue in the future.
;; NOTE: This module should NEVER import any other modules in Artanis!!!

(define-module (artanis env)
  #:use-module (artanis version)
  #:re-export (artanis-version)
  #:export (*handlers-table*
            *conf-hash-table*
            *conn-pool*
            *before-response-hook*
            *after-request-hook*
            *sql-mapping-lookup-table*))

;; WARNING: For concurrency in green-thread, all these stuffs should be immutable
;;          in the run time!

;; table structure:
;; '((rule-handler-key (handler . keys)) ...)
;; for example:
;; `(("GET \"/photo/:id/edit\"" (,(lambda (req ..) ...) . id)))  
(define *handlers-table* (make-hash-table))
(define *conf-hash-table* (make-hash-table))

;; NOTE: pool size equals to workers (work queues)
;; TODO: Should be pool of pool.
;;       In principle, each worker need just one connection because of green-thread.
;;       But async needs non-block, so we need a pool for each worker since each conn
;;       could be scheduled by EWOULDBREAK.
(define *conn-pool* #f)

(define *before-response-hook* (make-hook 2))
(define *after-request-hook* (make-hook 2))

;; TODO: I don't have much time for it but it should be RB-Tree in the future
(define *sql-mapping-lookup-table* (make-hash-table))
