# ADR-0001 — Operations memiliki batas penerimaan PO

**Status:** diterima untuk slice pertama. **Tanggal:** 28 Oktober 2026. **Owner:** Purchase dan Operations.

## Konteks

PO ditulis Commercial, GRN dan stok ditulis Operations. Dua GRN paralel dapat melewati toleransi over-receipt 0% bila keduanya membaca proyeksi `received_qty` Purchase yang tertunda. Transaksi SQL lintas owner dilarang oleh [standar repository](../engineering/repository-standards.md).

## Keputusan

Event `purchase.order.approved.v1` membuat `inventory.receipt_limits` per PO line. Operations menjadi owner remaining qty dan menaikkan received counter dalam transaksi yang sama dengan GRN, stock movement dan balance. Purchase memperbarui status PO dari event `warehouse.goods_receipt.posted.v1`; proyeksi itu tidak dipakai untuk guard GRN. PO amendment setelah approval tidak didukung slice pertama. Event belum diproses membuat GRN menunggu.

## Konsekuensi dan bukti

Keputusan menjaga over-receipt tanpa distributed transaction, tetapi receipt menunggu consumer event dan membutuhkan reconciler. Constraint DB membatasi `received≤approved`; uji PostgreSQL 18 menerima 6+4 dari limit 10 dan menolak tambahan 1. Event duplicate diabaikan lewat inbox+unique source. Detail [FSD-001](../features/first-slice-fsd.md).
